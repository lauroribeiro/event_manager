require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'

API_KEY = 'AIzaSyCz0E43CKdEkslpF5F42L9nmqE35Fjnqmc'.freeze

def clean_zipcode(zipcode)
  zipcode.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  return '0000000000' if phone_number.length < 10 || phone_number.length > 11

  return phone_number if phone_number.length == 10

  phone_number.length == 11 && phone_number[0] == 1 ? phone_number[1..-1] : '0000000000'
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

  zipcode = clean_zipcode(row[:zipcode].to_s)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_letter.result(binding)

  save_thank_you_letter(id, form_letter)
end
