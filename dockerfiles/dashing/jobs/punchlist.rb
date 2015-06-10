#require 'rest-client'
#require 'json'

username=0
password=0
project=0
widgets=['company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11','company_12']
count=0

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|



  widgets.each do |e|
    send_event(e, {title: e, open: count, ready: rand(100), complete: rand(200), closed: rand(300)})
    count += 1
  end
end
