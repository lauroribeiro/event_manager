require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'time'
require 'date'

API_KEY = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'.freeze

def clean_zipcode(zipcode)
  zipcode.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  clean_number = phone_number.gsub(/\D/, '')

  return '0000000000' if clean_number.length < 10 || clean_number.length > 11

  return clean_number if clean_number.length == 10

  clean_number.length == 11 && clean_number[0] == 1 ? clean_number[1..-1] : '0000000000'
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = API_KEY

  begin
    civic_info.representative_info_by_address(
      address: zipcode, levels: 'country', roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue(Google::Apis::ClientError)
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_registration_hour(contents)
  reg_dates = []
  contents.each do |row|
    reg_dates << row[:regdate]
  end
  date_times = reg_dates.map { |date| DateTime.strptime(date, '%m/%d/%y %H:%M') }
  peak_hours = date_times.reduce(Hash.new(0)) do |hash, date_time|
    hash[date_time.hour] += 1
    hash
  end
  # date_time = reg_dates.map { |date| date.strftime('%d/%m/%Y') }
  print peak_hours
end

def print_info(name, phone_number, zipcode, legislators)
  legislators_names = legislators.instance_of?(Array) ? legislators.map(&:name).join(', ') : legislators
  puts "Name: #{name}, phone number: #{phone_number}, zipcode: #{zipcode}, legislators: #{legislators_names}"
end

puts 'EventManager Initialized!'

template_letter = File.read('form_letter.erb')
erb_letter = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  phone_number = clean_phone_number(row[:homephone].to_s)

  zipcode = clean_zipcode(row[:zipcode].to_s)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_letter.result(binding)

  print_info(name, phone_number, zipcode, legislators)

  #save_thank_you_letter(id, form_letter)
end

#peak_registration_hour(contents)
