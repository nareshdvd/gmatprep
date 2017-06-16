# plan = Plan.create({"name"=>"Free Plan", "amount"=>0.0, "currency"=>"usd", "paper_count"=>2, "interval"=>"weeks", "interval_count"=>1})
# admin_role = Role.create(name: Role::ADMIN)
# candidate_role = Role.create(name: Role::CANDIDATE)
# easy = Level.create(name: Level::EASY, weight: 1)
# medium = Level.create(name: Level::MEDIUM, weight: 2)
# hard = Level.create(name: Level::HARD, weight: 3)

# a = Category.create(name: "Category A")
# b = Category.create(name: "Category B")
# cate_p = Category.create(name: Category::PASSAGE)

# admin = User.new
# admin.mark_for_admin_role
# admin.email = "admin@gmatprep.com"
# admin.password = "password"
# admin.password_confirmation = "password"
# admin.save
# admin.roles << admin_role
# user = User.create(email: "candidate001@gmail.com", password: "password", password_confirmation: "password")
# user = User.create(email: "candidate002@gmail.com", password: "password", password_confirmation: "password")

ActiveRecord::Base.connection.execute("INSERT INTO score_schemes (deduction, score, created_at, updated_at) VALUES (1 , 48, NOW(), NOW()), (2 , 47, NOW(), NOW()), (3 , 46, NOW(), NOW()), (4 , 45, NOW(), NOW()), (5 , 44, NOW(), NOW()), (6 , 43, NOW(), NOW()), (7 , 42, NOW(), NOW()), (8 , 41, NOW(), NOW()), (9 , 40, NOW(), NOW()), (10, 39, NOW(), NOW()), (11, 38, NOW(), NOW()), (12, 38, NOW(), NOW()), (13, 37, NOW(), NOW()), (14, 36, NOW(), NOW()), (15, 36, NOW(), NOW()), (16, 35, NOW(), NOW()), (17, 34, NOW(), NOW()), (18, 33, NOW(), NOW()), (19, 32, NOW(), NOW()), (20, 31, NOW(), NOW()), (21, 30, NOW(), NOW()), (22, 29, NOW(), NOW()), (23, 28, NOW(), NOW()), (24, 28, NOW(), NOW()), (25, 27, NOW(), NOW()), (26, 27, NOW(), NOW()), (27, 26, NOW(), NOW()), (28, 26, NOW(), NOW()), (29, 25, NOW(), NOW()), (30, 24, NOW(), NOW()), (31, 23, NOW(), NOW()), (32, 23, NOW(), NOW()), (33, 22, NOW(), NOW()), (34, 22, NOW(), NOW()), (35, 21, NOW(), NOW()), (36, 21, NOW(), NOW()), (37, 20, NOW(), NOW()), (38, 20, NOW(), NOW()), (39, 19, NOW(), NOW()), (40, 19, NOW(), NOW()), (41, 18, NOW(), NOW()), (42, 17, NOW(), NOW()), (43, 16, NOW(), NOW()), (44, 16, NOW(), NOW()), (45, 15, NOW(), NOW()), (46, 15, NOW(), NOW()), (48, 12, NOW(), NOW())")