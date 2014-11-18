require 'highline/import'
require 'json'
require 'mechanize'
require 'mongo'
require 'nokogiri'
require 'thread'

include Mongo

LOGIN_FORM = "https://www.courserank.com/stanford/main"
CLASS_BASE_URL = "https://www.courserank.com/stanford/course?id="
COMMENTS_BASE_URL = "https://www.courserank.com/stanford/target/comment_sort"
GRADES_BASE_URL = "https://www.courserank.com/stanford/target/course_grades"

username = ask("Username: ") { |q| q.echo = true }
password = ask("Password: ") { |q| q.echo = "*" }

def getMechanizeInstance(username, password)
    m = Mechanize.new
    m.user_agent = 'Mac Safari'
    m.get(LOGIN_FORM) do |page|
        page.form_with(:id => 'loginForm') do |f|
            f.username = username
            f.password = password
        end.click_button
    end
    return m
end

def getClassContents(m, id)

    begin
        result = Hash.new

        class_url = CLASS_BASE_URL + id
        m.get(class_url) do |page|

            # Get basic information off of the page
            contents = page.content
            result["title"] = page.at('head meta[property="og:title"]')[:content]
            result["description"] = page.at('head meta[property="og:description"]')[:content]
            result["avg_grade"] = page.at('head meta[property="courserankdev:avg_grade"]')[:content]
            result["avg_rating"] = page.at('head meta[property="courserankdev:avg_rating"]')[:content]
            result["og_url"] = page.at('head meta[property="og:url"]')[:content]

            # Extract the token from the page and use it to fetch all the reviews
            pattern = /<script type="text\/javascript">token=\'(\w+)\';<\/script>/
            token = pattern.match(contents).captures
            comments_source = m.post(COMMENTS_BASE_URL, {
                    "courseId" => id,
                    "sort" => "dateD",
                    "token" => token
                })

            # Source code sanitization necessary for Nokogiri to read properly
            # (I cannot believe the source is this shoddy)
            sanitized_source = comments_source.body.gsub(/found this review helpful<\/span>/, "")
            sanitized_source = sanitized_source.gsub(/&bull;/, "")

            comments = Array.new
            commentsXML = Nokogiri::HTML(sanitized_source)
            commentsXML = commentsXML.css("div.comment")
            commentsXML.each do |commentXML|
                if commentXML.at_css("div.commentNonePrompt").nil?
                    body = commentXML.at_css("div.commentBody")
                    instructor = commentXML.at_css("span.profName")
                    
                    # Extract things from commentHeadLeft with Regex
                    lefthead = commentXML.at_css("div.commentHeadLeft")
                    quarterYear = /([A-Z][a-z]+) (\d{4}-\d{4})/.match(lefthead.content)
                    stars = commentXML.to_s.scan(/FullYellow/)
                    grade = /\|\s+([A-Z][\+\-\s])/.match(lefthead.content)
                    upvotes = commentXML.at_css('span[id^="commentAgree"]')
                    votes = commentXML.at_css('span[id^="commentRatings"]')

                    # Save to a comment object
                    comment = Hash.new
                    unless body.nil?
                        comment["body"] = body.content
                    end
                    unless instructor.nil?
                        comment["instructors"] = instructor.content.gsub("\t", " ").gsub("\n", " ").strip
                    end
                    unless quarterYear.nil?
                        comment["quarter"], comment["year"] = quarterYear.captures
                    end
                    unless stars.nil?
                        comment["stars"] = stars.count
                    end
                    unless grade.nil?
                        comment["grade"] = grade.captures[0].strip
                    end
                    unless upvotes.nil?
                        comment["upvotes"] = upvotes.content.to_i
                        comment["downvotes"] = votes.content.to_i - comment["upvotes"].to_i
                    end
                    comments << comment
                end
            end

            result["comments"] = comments
        end

        grades_source = m.post(GRADES_BASE_URL, { "course" => id })
        gradesXML = Nokogiri::HTML(grades_source.body)
        official = Array.new
        officialGradesXML = gradesXML.css("official grade")
        officialGradesXML.each do |officialGradeXML|
            id = officialGradeXML.attr("id")
            count = officialGradeXML.attr("count")
            letter = officialGradeXML.at_css("view").content
            points = officialGradeXML.at_css("points").content
            grade = Hash.new
            grade["id"] = id
            grade["count"] = count
            grade["letter"] = letter
            grade["points"] = points
            official << grade
        end
        unofficial = Array.new
        unofficialGradesXML = gradesXML.css("unofficial grade")
        unofficialGradesXML.each do |unofficialGradeXML|
            id = unofficialGradeXML.attr("id")
            count = unofficialGradeXML.attr("count")
            letter = unofficialGradeXML.at_css("view").content
            points = unofficialGradeXML.at_css("points").content
            grade = Hash.new
            grade["id"] = id
            grade["count"] = count
            grade["letter"] = letter
            grade["points"] = points
            unofficial << grade
        end

        grades = Hash.new
        grades["official"] = official
        grades["unofficial"] = unofficial
        result["grades"] = grades

        return result

    rescue Mechanize::ResponseCodeError
    end

end

queue = Queue.new
(0..60000).to_a.each{|x| queue.push x}
(195000..200000).to_a.each{|x| queue.push x}
(205000..222500).to_a.each{|x| queue.push x}

client = MongoClient.new
db = client["courseriver"]
collection = db["courserank"]

m = getMechanizeInstance(username, password)
workers = (0...8).map do
    Thread.new do
        begin
            while x = queue.pop(true)
                contents = getClassContents(m, x.to_s)
                unless contents.nil?
                    id = collection.insert(contents)
                    puts "Inserted " + x.to_s + " at " + id.to_s
                end                
            end
        rescue ThreadError
        end
    end
end; "ok"
workers.map(&:join); "ok"
