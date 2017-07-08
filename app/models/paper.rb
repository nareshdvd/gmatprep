class Paper < ActiveRecord::Base
  belongs_to :subscription
  has_many :papers_questions, dependent: :destroy
  MINUTES = 75
  QUESTION_COUNT = 41
  MAX_SCORE = 48
  DARK_ORANGE   = "#ff9800"
  DARK_YELLOW   = "#ffeb3b"
  DARK_PURPLE   = "#7e57c2"
  DARK_GREEN    = "#0099FF"
  DARK_RED      = "#FF0000"
  DARK_YELLOWISH_GREEN = "#ef8b2c"
  serialize :category_scheme, JSON
  before_create :set_category_scheme

  scope :finished, -> {
    where("finish_time IS NOT NULL OR DATE_ADD(start_time, INTERVAL #{Paper::MINUTES} MINUTE) < NOW()")
  }

  def get_range_text(difficulty)
    difficulty = difficulty["y"].round(1)
    if difficulty >= 3 && difficulty <= 3.5
      "HIGH"
    elsif difficulty >= 2.5 && difficulty <= 2.9
      "MEDIUM HIGH"
    elsif difficulty >= 1.5 && difficulty <= 2.4
      "MEDIUM"
    else
      "LOW"
    end
  end

  def finished_questions
    return papers_questions.where("option_id IS NOT NULL")
  end

  def get_time_info
    paper = self
    ["#{Date.today.to_s(:db)} 00:00:00"] + paper.papers_questions.preload(question: :category).group_by{|pq| pq.question.category.id}.collect do |category_id, pqs|
      total_time = pqs.collect{|pq| pq.finish_time.to_i - pq.start_time.to_i}.sum
      total_count = pqs.count
      avg_sec_1 = (total_time * 1.0 / total_count).round
      "#{Date.today.to_s(:db)} 00:#{Time.at(avg_sec_1).utc.strftime('%M:%S')}"
    end
  end

  def get_sub_section_time_info
    paper = self
    return paper.papers_questions.preload(question: :category).group_by{|pq| pq.question.category.id}.inject(Hash.new) do |hash, (category_id, pqs)|
      total_time = pqs.collect{|pq| pq.finish_time.to_i - pq.start_time.to_i}.sum
      total_count = pqs.count
      avg_sec = (total_time * 1.0 / total_count).round
      minutes = (avg_sec / 60).to_i
      seconds = avg_sec % 60.to_i
      hash[pqs.first.question.category.name] = [minutes, seconds]
      hash
    end
  end

  def time_management_x_axis_data
    paper = self
    hash = paper.papers_questions.preload(question: :category).group_by{|pq| pq.question.category.id}.inject(Hash.new) do |hash, (category_id, pqs)|
      total_time = pqs.collect{|pq| pq.finish_time.to_i - pq.start_time.to_i}.sum
      total_count = pqs.count
      avg_sec = (total_time * 1.0 / total_count).round
      hash[pqs.first.question.category.name] = avg_sec
      hash
    end
    max_value = hash.values.max
    d1 = (max_value / 60).to_i
    d2 = max_value - (d1 * 60)
    d3 = 60 - d2
    d4 = max_value + d3
    data = hash.values.collect{ |t| ((Time.now.beginning_of_day + t.seconds).to_s(:db)).split(" ").collect{|dt| (dt.include?(":") ? dt.split(":").collect{|t| t.to_i} : dt.split("-").collect{|t| t.to_i})}.flatten }
    return {
      max: d4,
      data: data,
      keys: hash.keys
    }
  end

  def section_percentage_correct_incorrect_data
    data = self.papers_questions.preload(question: :category).group_by{|pq| pq.question.category.name}.inject(Hash.new{|h, k| h[k] = {}}) do |hash, (category_name, pqs)|
      hash[category_name]["correct"] = pqs.select{|pq| pq.is_correct?}.count
      hash[category_name]["in_correct"] = pqs.select{|pq| !pq.is_correct?}.count
      hash
    end
    data1 = []
    data1 << {name: "Correct", y: data[data.keys[0]]["correct"], color: DARK_GREEN}
    data1 << {name: "Incorrect", y: data[data.keys[0]]["in_correct"], color: DARK_RED}
    data2 = []
    data2 << {name: "Correct", y: data[data.keys[1]]["correct"], color: DARK_GREEN}
    data2 << {name: "Incorrect", y: data[data.keys[1]]["in_correct"], color: DARK_RED}
    data3 = []
    data3 << {name: "Correct", y: data[data.keys[2]]["correct"], color: DARK_GREEN}
    data3 << {name: "Incorrect", y: data[data.keys[2]]["in_correct"], color: DARK_RED}
    data = [
      {
        "section_name" => data.keys[0],
        "data" => data1
      },
      {
        "section_name" => data.keys[1],
        "data" => data2
      },
      {
        "section_name" => data.keys[2],
        "data" => data3
      }
    ]
    return data
  end

  def average_time_per_question
    data = papers_questions.select("COUNT(id) as id_count, ((CASE WHEN (question_number <=10) THEN 'I' WHEN (question_number > 10 AND question_number <= 20) THEN 'II' WHEN (question_number > 20 AND question_number <= 30) THEN 'III' WHEN (question_number > 30) THEN 'IV' END)) as id_group, SUM(TIMEDIFF(finish_time, start_time)) as total_time").group("id_group").as_json
    new_data = []
    data.each do |dt|
      total_time = dt["total_time"] / dt["id_count"]
      minutes = "%02d" % (total_time / 60)
      seconds = "%02d" % (total_time % 60)
      data1 = []
      if minutes.to_i == 1
        if seconds.to_i <= 49
          data1 << {name: "Average time", color: DARK_GREEN, y: 100, avg_time: "#{minutes}:#{seconds} Minutes"}
        else
          data1 << {name: "Average time", color: DARK_RED, y: 100, avg_time: "#{minutes}:#{seconds} Minutes"}
        end
      elsif minutes.to_i == 0
        data1 << {name: "Average time", color: DARK_GREEN, y: 100, avg_time: "#{minutes}:#{seconds} Minutes"}
      else
        data1 << {name: "Average time", color: DARK_RED, y: 100, avg_time: "#{minutes}:#{seconds} Minutes"}
      end
      new_data << {
        "section_name" => "Set #{dt['id_group']}",
        "data" => data1
      }
    end
    return new_data
  end

  def correct_percent_overall
    if (data = papers_questions.joins(question: :options).where("options.id = papers_questions.option_id").select("(CASE WHEN options.correct = 1 THEN 'correct' ELSE 'incorrect' END) as correct_incorrect, COUNT(papers_questions.id) as question_count").group("correct_incorrect").as_json.detect{|dt| dt["correct_incorrect"] == "correct"})
      (((data["question_count"] * 1.0) / 41) * 100).round
    else
      0
    end
  end

  def average_time_correct_incorrect
    data = papers_questions.joins(question: :options).where("options.id = papers_questions.option_id").select("(CASE WHEN options.correct = 1 THEN 'correct' ELSE 'incorrect' END) as correct_incorrect, SUM(TIMEDIFF(papers_questions.finish_time, papers_questions.start_time)) as total_time, COUNT(papers_questions.id) as pq_count").group("correct_incorrect").as_json
    if data.size != 2
      if data[0]["correct_incorrect"] == "correct"
        data[1] = {
          "correct_incorrect" => "incorrect",
          "average_time" => 0,
          "pq_count" => 0,
          "total_time" => 0
        }
      else
        data[1] = {
          "correct_incorrect" => "correct",
          "average_time" => 0,
          "pq_count" => 0,
          "total_time" => 0
        }
      end
    end
    data.each do |dt|
      if dt["total_time"] == 0 && dt["pq_count"] == 0
        dt["average_time"] = 0
      else
        dt["average_time"] = ((dt["total_time"] * 1.0) / dt["pq_count"])
      end
      dt.delete("total_time")
    end
    data = [
      data.detect{|dt| dt["correct_incorrect"] == "correct"},
      data.detect{|dt| dt["correct_incorrect"] == "incorrect"}
    ]
    max = [data[0]["average_time"], data[1]["average_time"]].max
    if max % 60 == 0
      max = max + 60
    else
      max = max + (max % 60) + 60
    end
    keys = ["Correct", "Incorrect"]
    data = data.collect{|dt| t = dt["average_time"]; ((Time.now.beginning_of_day + t.seconds).to_s(:db)).split(" ").collect{|dt| (dt.include?(":") ? dt.split(":").collect{|t| t.to_i} : dt.split("-").collect{|t| t.to_i})}.flatten }
    return {
      max: max,
      data: data,
      keys: keys
    }
  end

  def average_difficulty_level
    data = papers_questions.joins(:question).select("((CASE WHEN (question_number <=10) THEN 'I' WHEN (question_number > 10 AND question_number <= 20) THEN 'II' WHEN (question_number > 20 AND question_number <= 30) THEN 'III' WHEN (question_number > 30) THEN 'IV' END)) as id_group, group_concat(questions.level_id) as level_ids").where("questions.category_id != ?", 3).group("id_group").as_json
    level_score = {
      "1" => 0.1,
      "2" => 0.2,
      "3" => 0.5
    }
    inx = 0
    colors = {
      'LOW' => DARK_RED,
      'MEDIUM' => DARK_YELLOW,
      "MEDIUM HIGH" => DARK_YELLOWISH_GREEN,
      "HIGH" => DARK_GREEN
    }
    hash = data.inject(Hash.new{|h, k| h[k] = {}}) do |hash, set_data|
      difficulty = set_data["level_ids"].split(",").collect{|level_id| level_score[level_id]}.sum
      hash[set_data["id_group"]]["y"] = difficulty
      difficulty_level = get_range_text(hash[set_data["id_group"]])
      hash[set_data["id_group"]]["color"] = colors[difficulty_level]
      inx += 1
      hash
    end
    return [
      hash["I"],
      hash["II"],
      hash["III"],
      hash["IV"]
    ], colors
  end

  def bar_colors
    {
      1 => [DARK_ORANGE],
      2 => [DARK_YELLOW, DARK_PURPLE],
      3 => [DARK_ORANGE, DARK_YELLOW, DARK_PURPLE],
      4 => [DARK_ORANGE, DARK_YELLOW, DARK_PURPLE, DARK_GREEN],
      "green-red" => [DARK_GREEN, DARK_RED]
    }
  end

  def correct_percentage
    paper = self
    data = paper.papers_questions.first(30).each_slice(10).collect do |group|
      (((group.select{|pq| pq.is_correct?}.count * 1.0) / group.size) * 100).round
    end
    last_group = paper.papers_questions.last(11)
    data << (((last_group.select{|pq| pq.is_correct?}.count * 1.0) / last_group.size) * 100).round
  end

  def incorrect_percentage
    paper = self
    data = paper.papers_questions.first(30).each_slice(10).collect do |group|
      (((group.select{|pq| !pq.is_correct?}.count * 1.0) / group.size) * 100).round
    end
    last_group = paper.papers_questions.last(11)
    data << (((last_group.select{|pq| !pq.is_correct?}.count * 1.0) / last_group.size) * 100).round
  end

  def correct_incorrect_graph_data
    data = {
      series: [
      ]
    }
    data[:series] << {data: correct_percentage, name: "Correct", color: DARK_GREEN}
    data[:series] << {data: incorrect_percentage, name: "Incorrect", color: DARK_RED}
    return data
  end


  def percentile
    score = calculate_score
    if (score_scheme = ScoreScheme.find_by(score: score)).present?
      return score_scheme.score_percentile.to_i
    else
      return 0
    end
  end

  def get_chart_data
    data = {}
    paper = self
    paper.papers_questions.preload(question: :level).collect{|pqs| pqs.question.level.id}.each_with_index do |level_id, inx|
      data[inx] = {level_id: level_id}
      if inx != 0
        if level_id < data[inx - 1][:level_id]
          data[inx][:val] = data[inx - 1][:val] - 0.7
        elsif (level_id == data[inx - 1][:level_id]) && data[inx-2].present? && (level_id == data[inx - 2][:level_id])
          if level_id == 1
            data[inx][:val] = data[inx - 1][:val] - 0.7
          else level_id == 3
            data[inx][:val] = data[inx - 1][:val] + 0.5
          end
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
    last_two_questions = papers_questions.where("question_number IN (40, 41)")
    if last_two_questions.count >= 1
      deductions -= last_two_questions.select{|pq| !pq.is_correct?}.count
    end
    return deductions
  end

  def calculate_score
    deductions = get_deductions
    if (score_scheme = ScoreScheme.find_by(deduction: deductions)).present?
      pqs = papers_questions.where("question_number IN (?)", (1..10).to_a)
      return score_scheme.score - pqs.select{|pq| !pq.is_correct?}.count
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

  def finished?
    self.finish_time.present? || (self.start_time + Paper::MINUTES.minutes < Time.now)
  end

  def all_answered?
    self.papers_questions.last.question_number == 41 && self.papers_questions.last.answered?
  end

  def unfinished?
    !finished?
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
