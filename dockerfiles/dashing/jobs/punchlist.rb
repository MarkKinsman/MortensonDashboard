#equire 'rest-client'
#require 'json'

username=0
password=0
project=0
widgets=['company_0','company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11']
count=1

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|
  leaders = Hash.new({value: 0})
  companies = Hash.new({title: "", open: 0, ready: 0, complete: 0, closed: 0, total: 0})


  widgets.each do |e|
    o = rand(100)
    r = rand(20)
    c = rand(20)
    f = rand(100)
    companies[e] = {title: e, open: o, ready: r, complete: c, closed: f, total: o + r + c + f }
    value = (f*100) / (o + r + c + f )
    leaders[e] = {label: e, value: "#{value}%"}
  end

  companies_array = companies.sort_by { |k, v| v[:open] }

  11.times do |i|
    send_event('company_#{i}', {open: companies_array[i][:open], ready: companies_array[i][:ready], complete: companies_array[i][:complete], closed: companies_array[i][:closed] })
  end
  send_event('leaderboard', { items: leaders.values })
end
