require 'rest-client'
require 'json'

username=0
password=0
project=0
widgets=['company1','company2','company3','company4','company5','company6','company7','company8','company9','company10','company11','company12']
count=0

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|



  widgets.each do |e|
    send_event(e, {open: count, ready: rand(100), complete: rand(200), closed: rand(300)})
    count += 1
  end
end
