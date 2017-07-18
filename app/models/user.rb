class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:google_oauth2, :facebook]
  has_and_belongs_to_many :roles
  has_many :subscriptions, dependent: :destroy
  has_many :papers, through: :subscriptions
  has_many :identities, dependent: :destroy
  after_create :assign_candidate_role_to_user, if: Proc.new{|user| !user.is_admin? }
  after_create :add_registration_info_to_influx
  after_create :subscribe_for_free_plan, if: Proc.new{|user| !user.is_admin? }

  def self.from_omniauth(auth)
    @identity = Identity.find_with_omniauth(auth)
    if @identity.nil?
      @identity = Identity.create_with_omniauth(auth)
    end
    if @identity.user.blank?
      if (user = find_by_email(auth.info.email)).blank?
        @identity.create_user({email: auth.info.email, password: Devise.friendly_token[0, 20]})
      else
        @identity.user_id = user.id
        @identity.save
      end
    end
    @identity.user
  end

  def add_registration_info_to_influx
    InfluxMonitor.push_to_influx("registered", {user: self.roles.first.name})
  end

  def is_manish?
    self.email == 'manishtestgmprep@gmp.com'
  end

  def mark_for_admin_role
    @marked_for_admin = true
  end

  def assign_candidate_role_to_user
    role = Role.where(name: Role::CANDIDATE).first
    self.roles << role
  end

  def subscribe_for_free_plan
    plan = Plan.where(name: Plan::FREE_PLAN).first
    self.subscriptions.create(plan_id: plan.id, start_date: Date.today, end_date: 1000.days.from_now)
  end

  def is_admin?
    @marked_for_admin || (self.roles.where(name: Role::ADMIN).count != 0)
  end

  def is_candidate?
    self.roles.where(name: Role::CANDIDATE).count != 0
  end

  def active_subscription
    return self.subscriptions.where(is_active: true).last
  end

  def free_subscription
    @free_subscription ||= subscriptions.find_by_plan_id(Plan.free_plan)
  end

  def available_tests
    [1,2,3,4]
  end

  def available_plans_to_buy
    user = self
    Plan.joins("LEFT OUTER JOIN subscriptions ON subscriptions.plan_id=plans.id").joins("LEFT OUTER JOIN users ON users.id=subscriptions.user_id").where("
        ((
           subscriptions.user_id=#{user.id}
         ) AND
        ((CASE
          WHEN plans.interval='MONTH' THEN DATE_ADD(subscriptions.created_at, INTERVAL plans.interval_count MONTH)
          WHEN plans.interval='WEEK' THEN DATE_ADD(subscriptions.created_at, INTERVAL plans.interval_count WEEK)
        END) > NOW())) OR (
          subscriptions.user_id IS NULL
        )
    ")
  end

  def get_unseen_question(level_id, category_id, only_free_plan_questions = false)
    conditions = "questions.level_id=? AND questions.category_id=? AND questions.marked_for_free_plan = ?"
    values = [level_id, category_id, (only_free_plan_questions ? true : false)]
    user = self
    used_question_ids = Question.select("questions.id as id").joins("INNER JOIN papers_questions ON papers_questions.question_id=questions.id").joins("INNER JOIN papers ON papers.id=papers_questions.paper_id").joins("INNER JOIN subscriptions ON subscriptions.id=papers.subscription_id").joins("INNER JOIN users ON users.id=subscriptions.user_id").where("users.id = ?", user.id).where(conditions, *values).collect(&:id)
    if used_question_ids.present?
      unused_question = Question.where(conditions, *values).where("questions.id NOT IN (?)", used_question_ids).order("used_in_free_plan DESC").first
    else
      unused_question = Question.where(conditions, *values).order("used_in_free_plan DESC").first
    end
    unused_question.set_used_in_free_plan if !unused_question.used_in_free_plan
    return unused_question
  end


  def get_unseen_passage(need_passage_with_four_questions = false, only_free_plan_questions = false)
    values = []
    conditions = "questions.marked_for_free_plan = ?"
    values << (only_free_plan_questions ? true : false)
    conditions += " #{ (conditions.present? ? 'AND' : '') } passages.question_count = ?"
    values << (need_passage_with_four_questions ? 4 : 3)
    user = self
    used_passage_ids = Passage.select("passages.id").joins("INNER JOIN questions ON questions.passage_id=passages.id").joins("INNER JOIN papers_questions ON papers_questions.question_id=questions.id").joins("INNER JOIN papers ON papers.id=papers_questions.paper_id").joins("INNER JOIN subscriptions ON subscriptions.id=papers.subscription_id").joins("INNER JOIN users ON users.id=subscriptions.user_id").where("users.id = ?", user.id).where(conditions, *values).collect(&:id)
    if used_passage_ids.present?
      passage = Passage.joins(:questions).where(conditions, *values).where("passages.id NOT IN (?)", used_passage_ids).order("questions.used_in_free_plan DESC").first
    else
      passage = Passage.joins(:questions).where(conditions, *values).order("questions.used_in_free_plan DESC").first
    end
    passage.questions.update_all({used_in_free_plan: true}) if !passage.questions.select("questions.used_in_free_plan").first.used_in_free_plan
    return passage
  end

  def in_progress_paper
    current_test
  end

  def last_purchased
    subscriptions.purchased.last
  end

  def current_subscription
    if (lp = last_purchased).present? && lp.not_elapsed? && lp.not_exhausted?
      return lp
    else
      return nil
    end
  end

  def get_or_add_pending_subscription(plan, payment_params)
    if (unpaid_plan_subscription = self.subscriptions.unpaid.where("plan_id=?", plan.id).first).blank?
      unpaid_plan_subscription = self.subscriptions.create(plan_id: plan.id)
      invoice, payment, payment_method = unpaid_plan_subscription.add_invoice(payment_params)
    else
      invoice = unpaid_plan_subscription.invoice
      payment = invoice.payments.preload(:payment_methods).joins(:payment_methods).where("payment_methods.name=? AND payments.status=?", payment_params[:payment_method], Payment::STATUS[:pending]).first
      payment, payment_method = invoice.create_pending_payment(payment_params) if payment.blank?
      if payment_method.blank?
        payment_method = payment.get_or_add_payment_method(payment_params[:payment_method], payment_params.except(:payment_method))
      end
      #payment_method = payment.payment_methods.detect{|payment_method| payment_method.name == payment_params[:payment_method]}
    end
    payment_method.set_params(payment_params)
    return unpaid_plan_subscription, invoice, payment, payment_method
  end

  def current_test
    if current_subscription.present?
      if (last_paper = current_subscription.papers.last).present? && last_paper.unfinished?
        current_subscription.papers.last
      else
        return nil
      end
    elsif (last_paper = free_subscription.papers.last).present? && last_paper.unfinished?
      return last_paper
    else
      nil
    end
  end

  def remaining_test_count
    ([free_subscription] + [current_subscription]).compact.collect{|subscription| subscription.remaining_paper_count}.sum
  end

  def completed_tests
    subscriptions.joins(:papers).preload(:papers).where("papers.finish_time IS NOT NULL").collect{|sub| sub.papers}.flatten.uniq
  end

  def completed_test_count
    subscriptions.joins(:papers).where("papers.finish_time IS NOT NULL").count
  end

  def get_available_plans(overall = false)
    user = self
    question_type = "(CASE
      WHEN category_id = 1 AND level_id = 1 THEN '1-1'
      WHEN category_id = 1 AND level_id = 2 THEN '1-2'
      WHEN category_id = 1 AND level_id = 3 THEN '1-3'
      WHEN category_id = 2 AND level_id = 1 THEN '2-1'
      WHEN category_id = 2 AND level_id = 2 THEN '2-2'
      WHEN category_id = 2 AND level_id = 3 THEN '2-3'
      ELSE
        questions.passage_id
    END) as question_type"
    if !overall
      min_questions_info = Question.select("COUNT(DISTINCT questions.id) as question_count, #{question_type}").joins("LEFT OUTER JOIN papers_questions ON papers_questions.question_id=questions.id").joins("LEFT OUTER JOIN papers ON papers.id=papers_questions.paper_id").joins("LEFT OUTER JOIN subscriptions ON subscriptions.id=papers.subscription_id").joins("LEFT OUTER JOIN users ON users.id=subscriptions.user_id").where("questions.marked_for_free_plan = ?", false).where("(subscriptions.user_id IS NULL OR subscriptions.user_id != ?)", user.id).group("question_type")
    else
      min_questions_info = Question.select("COUNT(DISTINCT questions.id) as question_count, #{question_type}").where("questions.marked_for_free_plan = ?", false).group("question_type")
    end
    passage_3_count = 0
    passage_4_count = 0
    other_category_questions = []
    min_questions_info.each do |question_info|
      if !question_info.question_type.include?("-")
        if question_info.question_count == 3
          passage_3_count += 1
        else
          passage_4_count += 1
        end
      else
        other_category_questions << question_info
      end
    end
    data = {
      passage_3_count: passage_3_count,
      passage_4_count: passage_4_count
    }

    if (min_other_category_ques = other_category_questions.min_by{|ca_q| ca_q.question_count}).present?
      if (min_papers_by_min_cate_ques = (min_other_category_ques.question_count / 14).to_i) >= 1
        min_papers_by_passage_3 = (passage_3_count / 3).to_i
        min_papers_by_passage_4 = passage_4_count.to_i
        available_paper_count = [min_papers_by_passage_3, min_papers_by_passage_4, min_papers_by_min_cate_ques].min
        plans = {
          7 => [1, 3, 5],
          6 => [1, 3, 5],
          5 => [1, 3, 5],
          4 => [1, 3],
          3 => [1, 3],
          2 => [1],
          1 => [1]
        }
        available_plans = Plan.where(paper_count: plans[available_paper_count]).where("name != ?", Plan::FREE_PLAN)
      else
        available_plans = nil
      end
    else
      available_plans = nil
    end
    return available_plans
  end

  def test_script(subscription_id, correct_info = nil)
    user = self
    subscription = user.subscriptions.find_by_id(subscription_id)
    subscription.plan.paper_count.times do
      paper = subscription.papers.create(start_time: Time.now)
      question = paper.add_question(true)
      question.start_time = Time.now
      while question.question_number <= 41 do
        if correct_info == "all_correct"
          question.mark_correct
        elsif correct_info == "all_incorrect"
          question.mark_incorrect
        else
          action = ["mark_correct", "mark_incorrect"].sample
          question.send(action.to_sym)
        end
        question.finish_time = question.start_time + (100..200).to_a.sample.seconds
        question.save
        if question.question_number < 41
          question = paper.add_question
        else
          paper.paper_finish_displayed = true
          paper.finish_time = Time.now
          paper.save
          break
        end
      end
    end
  end
end
