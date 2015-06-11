#equire 'rest-client'
#require 'json'

username=0
password=0
project=0
widgets=['company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11','company_12']
leaders = Hash.new({value: 0})
count=1

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|



  widgets.each do |e|
    o = rand(100)
    r = rand(20)
    c = rand(20)
    f = rand(100)
    send_event(e, {title: e, open: o, ready: r, complete: c, closed: f})
    leaders[e] = {label: e, value: (f / (o + r + c + f ) * 100)}
  end
  send_event('leaderboard', { items: leaders.values})
end
