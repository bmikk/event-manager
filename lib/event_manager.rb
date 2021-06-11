require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  num = phone_number.split('').reject { |item| /\D/ =~ item }.join('')
  length = num.length
  if length < 10 || length > 11 || (length == 11 && num[0] == '1')
    num = '0000000000'
    num
  elsif length == 10
    num
  else
    num = num[-10, 10]
    num
  end
end

def find_registration_hour(date)
  date_format = '%m/%d/%Y %H:%M'
  formatted_date = DateTime.strptime(date, date_format)
  hour = formatted_date.hour
  hour
end

def find_registration_weekday(date)
  date_format = '%m/%d/%Y %H:%M'
  formatted_date = DateTime.strptime(date, date_format)
  weekday = formatted_date.wday
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials

    legislator_names = legislators.map(&:name).join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  date = row[:regdate]
  name = row[:first_name]

  hour = find_registration_hour(date)

  weekday = find_registration_weekday(date)
  
  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id, form_letter)

  #puts "#{name} registered in hour #{hour}, and their phone number is #{phone_number}."

  puts weekday

end



