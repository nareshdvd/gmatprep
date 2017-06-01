# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
plan = Plan.create({"name"=>"Free Plan", "amount"=>0.0, "currency"=>"usd", "paper_count"=>2, "interval"=>"weeks", "interval_count"=>1})
admin_role = Role.create(name: Role::ADMIN)
candidate_role = Role.create(name: Role::CANDIDATE)
easy = Level.create(name: Level::EASY, weight: 1)
medium = Level.create(name: Level::MEDIUM, weight: 2)
hard = Level.create(name: Level::HARD, weight: 3)

a = Category.create(name: "Category A")
b = Category.create(name: "Category B")
cate_p = Category.create(name: Category::PASSAGE)

admin = User.new
admin.mark_for_admin_role
admin.email = "admin@gmatprep.com"
admin.password = "password"
admin.password_confirmation = "password"
admin.save
admin.roles << admin_role
user = User.create(email: "candidate001@gmail.com", password: "password", password_confirmation: "password")
user = User.create(email: "candidate002@gmail.com", password: "password", password_confirmation: "password")

# 100.times do |t|
#   q = Question.create(description: "Category A Easy Question", level_id: easy.id, category_id: a.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Category B Easy Question", level_id: easy.id, category_id: b.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Category A Medium Question", level_id: medium.id, category_id: a.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Category B Medium Question", level_id: medium.id, category_id: b.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end

#   q = Question.create(description: "Category A Hard Question", level_id: hard.id, category_id: a.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Category B Hard Question", level_id: hard.id, category_id: b.id, passage_id: nil, marked_for_free_plan: true)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
# end

# 20.times do |k|
#   passage = Passage.create(title: "Passage #{k} with three questions", description: "Passage #{k} with three questions", question_count: 3)
#   q = Question.create(description: "Passage #{k} Category A Easy Question", level_id: easy.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Passage #{k} Category A Medium Question", level_id: medium.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Passage #{k} Category A Hard Question", level_id: hard.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
# end

# 10.times do |k|
#   passage = Passage.create(title: "Passage #{k} with four questions", description: "Passage #{k} with four questions", question_count: 4)
#   q = Question.create(description: "Passage #{k} Category B Easy Question", level_id: easy.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Passage #{k} Category B Medium Question", level_id: medium.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Passage #{k} Category B Hard Question", level_id: hard.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
#   q = Question.create(description: "Passage #{k} Category B Hard Question", level_id: hard.id, category_id: cate_p.id, passage_id: nil, marked_for_free_plan: true, passage_id: passage.id)
#   correct_one = (rand * 5).to_i
#   5.times.each do |m|
#     q.options.create(description: "Option #{m + 1} #{m == correct_one ? 'Correct one' : ''}", correct: (m==correct_one ? true : false))
#   end
# end