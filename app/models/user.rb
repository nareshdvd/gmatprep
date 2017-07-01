class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_and_belongs_to_many :roles
  has_many :subscriptions, dependent: :destroy
  after_create :assign_candidate_role_to_user, if: Proc.new{|user| !user.is_admin? }
  after_create :add_registration_info_to_influx
  after_create :subscribe_for_free_plan, if: Proc.new{|user| !user.is_admin? }

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
    free_plan = Plan.find_by_name(Plan::FREE_PLAN)
    free_subscription = free_plan.subscriptions.where(user_id: self.id).last
    if !free_subscription.elapsed? && !free_subscription.exhausted?
      if free_subscription.current_test_id.present? && (test = Paper.find_by_id(free_subscription.current_test_id)).present? && !test.finished?
        return test
      end
    end
    self.subscriptions.paid_usable.where("subscriptions.current_test_id IS NOT NULL").each do |subscription|
      if subscription.current_test_id.present? && (test = Paper.find_by_id(subscription.current_test_id)).present? && !test.finished?
        return test
      end
    end
    return nil
  end
end
