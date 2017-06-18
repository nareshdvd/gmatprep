class Paper < ActiveRecord::Base
  belongs_to :subscription
  has_many :papers_questions, dependent: :destroy
  MINUTES = 75
  QUESTION_COUNT = 41
  serialize :category_scheme, JSON
  before_create :set_category_scheme


  def get_chart_data
    data = {}
    paper = self
    paper.papers_questions.preload(question: :level).collect{|pqs| pqs.question.level.id}.each_with_index do |level_id, inx|
      data[inx] = {level_id: level_id}
      if inx != 0
        if level_id < data[inx - 1][:level_id]
          data[inx][:val] = data[inx - 1][:val] - 0.7
        else
          data[inx][:val] = data[inx - 1][:val] + 0.5
        end
      else
        data[inx][:val] = level_id
      end
    end
    return data.collect{|inx, dt| dt[:val]}
  end

  def set_category_scheme
    arr = []
    14.times{ arr << 1}
    14.times{ arr << 2}
    self.category_scheme = arr.shuffle
  end

  def get_incorrect_answers_count
    papers_questions.joins(question: :options).where("papers_questions.option_id=options.id AND options.correct = ?", false).group("questions.level_id").count
  end

  def get_deductions
    deductions = 0
    get_incorrect_answers_count.each do |level, incorrect_count|
      deductions += (Level::SCORE[level] * incorrect_count).ceil
    end
    return deductions
  end

  def calculate_score
    deductions = get_deductions
    if (score_scheme = ScoreScheme.find_by(deduction: deductions)).present?
      return score_scheme.score
    else
      return 5
    end
  end

  def current_question
    if (paper_question = self.papers_questions.last).blank?
      paper_question = self.add_question(true)
    end
    return paper_question
  end

  def last_question_unanswered?
    self.papers_questions.last.unanswered?
  end

  def add_question(first = false)
    paper = self
    if first
      next_level = Level.medium
      next_category = paper.get_next_category
      question_id = paper.subscription.user.get_unseen_question(next_level.id, next_category.id, (paper.subscription.plan.name == Plan::FREE_PLAN)).id
    else
      if passage_needed?
        # need to fetch a passage
        need_passage_with_four_questions = paper.papers_questions.joins(:question).where("questions.passage_id IS NOT NULL").count == 9
        passage = paper.subscription.user.get_unseen_passage(need_passage_with_four_questions)
        question_id = passage.questions.first.id
      elsif passage_ends?
        # need to see the next level and next category to determine next question
        next_level = paper.get_next_level
        next_category = paper.get_next_category
        question_id = paper.subscription.user.get_unseen_question(next_level.id, next_category.id, (paper.subscription.plan.name == Plan::FREE_PLAN)).id
      elsif inside_passage?
        question_id = paper.papers_questions.last.question.passage.questions[paper.papers_questions.last.question.passage.questions.index(paper.papers_questions.last.question) + 1].id
      else
        next_level = paper.get_next_level
        next_category = paper.get_next_category
        question_id = paper.subscription.user.get_unseen_question(next_level.id, next_category.id, (paper.subscription.plan.name == Plan::FREE_PLAN)).id
      end
    end
    question_number = first ? 1 : (paper.papers_questions.last.question_number + 1)
    paper_question = paper.papers_questions.create(question_id: question_id, question_number: question_number, start_time: Time.now)
  end

  def passage_needed?
    passage_question_positions = [[6, 7, 8], [16, 17, 18], [26, 27, 28], [36, 37, 38, 39]]
    questions_added_yet_count = self.papers_questions.count
    passage_question_positions.collect{|pqs| pqs.first}.include?(questions_added_yet_count + 1)
  end

  def inside_passage?
    passage_question_positions = [[6, 7, 8], [16, 17, 18], [26, 27, 28], [36, 37, 38, 39]]
    questions_added_yet_count = self.papers_questions.count
    passage_question_positions.collect{|pqs| (pqs_temp = pqs.clone).shift; pqs_temp}.flatten.include?(questions_added_yet_count+1)
  end

  def passage_ends?
    passage_question_positions = [[6, 7, 8], [16, 17, 18], [26, 27, 28], [36, 37, 38, 39]]
    questions_added_yet_count = self.papers_questions.count
    passage_question_positions.collect{|pqs| pqs.last}.include?(questions_added_yet_count)
  end

  def get_next_level
    if self.papers_questions.count > 1
      if self.papers_questions.last.question.passage_id.present?
        first_passage_question_id = self.papers_questions.last.question.passage.questions.first.id
        last_passage_question = self.papers_questions[self.papers_questions.index(self.papers_questions.where(question_id: first_passage_question_id).first) - 1]
        second_last_passage_question = self.papers_questions[self.papers_questions.index(self.papers_questions.where(question_id: first_passage_question_id).first) - 2]
      else
        last_passage_question = self.papers_questions.last
        second_last_passage_question = self.papers_questions.last(2).first
      end
    else
      last_passage_question = self.papers_questions.first
      second_last_passage_question = nil
    end
    if second_last_passage_question.present? && (last_passage_question.question.level == second_last_passage_question.question.level)
      if last_passage_question.option.is_correct? && second_last_passage_question.option.is_correct?
        if Level::LEVELS[last_passage_question.question.level.weight + 1].blank?
          level = last_passage_question.question.level
        else
          level = Level.where(weight: last_passage_question.question.level.weight + 1).first
        end
      else
        if Level::LEVELS[last_passage_question.question.level.weight - 1].blank?
          level = last_passage_question.question.level
        else
          level = Level.where(weight: last_passage_question.question.level.weight - 1).first
        end
      end
    elsif last_passage_question.option.is_correct?
      level = last_passage_question.question.level
    else
      if Level::LEVELS[last_passage_question.question.level.weight - 1].blank?
        level = last_passage_question.question.level
      else
        level = Level.where(weight: last_passage_question.question.level.weight - 1).first
      end
    end
  end

  def get_next_category
    # category = Category.where("name != ? AND id != ?", Category::PASSAGE, self.papers_questions.last.question.category_id).first
    next_question_position = self.papers_questions.joins(:question).where("questions.passage_id IS NULL AND questions.category_id IN (?)", [1,2]).count
    Rails.logger.info "NEXT QUESTION POSITION : #{next_question_position}"
    category = Category.find_by_id(self.category_scheme[next_question_position])
    Rails.logger.info "CATEGORY SCHEME : #{self.category_scheme.inspect}"
    Rails.logger.info "NEXT CATEGORY ID: #{self.category_scheme[next_question_position].inspect}"
    return Category.find_by_id(self.category_scheme[next_question_position])
  end

  def next_question_number
    current_question.question_number + 1
  end

  def questions_finished
    current_question.question_number == QUESTION_COUNT
  end

  def remaining_seconds
    (self.start_time + (Paper::MINUTES).minutes) - Time.now
  end

  def formatted_remaining_time
    minutes = (remaining_seconds / 60).to_i
    hours = (minutes / 60).to_i
    if hours == 0
      seconds = remaining_seconds - (minutes * 60)
    else
      minutes = minutes - (hours * 60);
      seconds = remaining_seconds - (minutes * 60) - (hours * 60 * 60)
    end
    "%02d" % hours + ":" + "%02d" % minutes + ":" + "%02d" % seconds
  end
end
