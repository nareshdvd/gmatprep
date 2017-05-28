class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_and_belongs_to_many :roles
  has_many :subscriptions
  after_create :assign_candidate_role_to_user, if: Proc.new{|user| !user.is_admin? }
  after_create :subscribe_for_free_plan, if: Proc.new{|user| !user.is_admin? }

  def mark_for_admin_role
    @marked_for_admin = true
  end

  def assign_candidate_role_to_user
    role = Role.where(name: Role::CANDIDATE).first
    self.roles << role
  end

  def subscribe_for_free_plan
    plan = Plan.where(name: Plan::FREE_PLAN).first
    self.subscriptions.create(plan_id: plan.id)
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

  def get_unseen_question_id(level_id, category_id, only_free_plan_questions = false)
    conditions = "papers_questions.question_id IS NULL AND questions.level_id=? AND questions.category_id=?"
    values = [level_id, category_id]
    if only_free_plan_questions
      conditions += " AND questions.marked_for_free_plan=?"
      values << true
    end
    return Question.select("questions.id as id").joins("LEFT OUTER JOIN papers_questions ON papers_questions.question_id=questions.id").joins("LEFT OUTER JOIN papers ON papers.id=papers_questions.paper_id").joins("LEFT OUTER JOIN subscriptions ON subscriptions.id=papers.subscription_id").joins("LEFT OUTER JOIN users ON users.id=subscriptions.user_id AND users.id=#{self.id}").where(conditions, *values).first.try(:id)
  end


  def get_unseen_passage_id(need_passage_with_four_questions = false, only_free_plan_questions = false)
    conditions = "papers_questions.question_id IS NULL"
    values = []
    if only_free_plan_questions
      conditions += " AND questions.marked_for_free_plan = ?"
      values << true
    end
    if need_passage_with_four_questions
      conditions += " AND passages.question_count = ?"
      values << 4
    else
      conditions += " AND passages.question_count = ?"
      values << 3
    end
    return Passage.select("passages.id as id").joins("INNER JOIN questions ON questions.passage_id=passages.id").joins("LEFT OUTER JOIN papers_questions ON papers_questions.question_id=questions.id").joins("LEFT OUTER JOIN papers ON papers.id=papers_questions.paper_id").joins("LEFT OUTER JOIN subscriptions ON subscriptions.id=papers.subscription_id").joins("LEFT OUTER JOIN users ON users.id=subscriptions.user_id AND users.id=#{self.id}").where(conditions, *values).first.try(:id)
  end
end
