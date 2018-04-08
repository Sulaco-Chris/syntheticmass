require 'rspec'
require 'pry'
require 'fhir_client'
require './assertions'
require 'optparse'

# if ARGV[0].nil?
#   puts 'Must pass FHIR server endpoint as first argument.'
# end

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: ruby app.rb  URL [OPTIONS]"

  opt.on("-p","--patient PATIENT", "Specify a Patient ID for patient searches (the more complete a record, the better). This will guess one if not provided") do |patient|
    options[:patient] = patient
  end

  opt.on("-c","--city CITY", "Specify a city name for dashboard tests (attempts to find a city from patient list otherwise)") do |city|
    options[:city] = city
  end

  opt.on("-d","--condition CONDITION", "Specify a SNOMED condition(s) for dashboard test searches for patient filtering (defaults to 44054006)") do |condition|
    options[:condition] = condition
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end

end

unless ARGV[0].start_with? 'http'
  puts opt_parser
  exit
end

opt_parser.parse!

RSpec.configure do |c|
  c.add_setting :fhir_url, :default =>ARGV[0]
  c.add_setting :patient, :default => options[:patient]
  c.add_setting :city, :default => options[:city]
  c.add_setting :condition, :default => options[:condition] || "44054006"
end

RSpec::Core::Runner.run(['spec'], $stderr, $stdout)
