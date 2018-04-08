# Describes the requirements of a FHIR server using the Synthetic Mass Dashboard
describe 'Server (Dashboard)' do 

  include Crucible::Tests::Assertions

  url = RSpec.configuration.fhir_url
  patient = RSpec.configuration.patient
  city = RSpec.configuration.city
  condition = RSpec.configuration.condition

  before(:all) do

    @client = FHIR::Client.new(url)
    @client.default_json

    if patient.nil?
      response = @client.read_feed(FHIR::Patient) # fetch Bundle of Patients
      assert_response_ok(response)
      assert_bundle_response(response)
      @patient = response.resource.entry.first.resource
    else
      response = @client.read(FHIR::Patient, patient)
      assert_response_ok(response)
      assert_resource_type(response, FHIR::Patient)
      @patient = response.resource
    end

    @city = city
    if(city.nil?)
      response = @client.read_feed(FHIR::Patient) # fetch Bundle of Patients
      assert_response_ok(response)
      assert_bundle_response(response)
      @city = response.resource.entry.find{|p| !p.try(:resource).try(:address).try(:first).nil?}.try(:resource).try(:address).try(:first).try(:city)
    end

    @condition = condition

  end

  # https://syntheticmass.mitre.org/fhir/Patient?gender=female&_count=20&address-city=Petersham
  # https://syntheticmass.mitre.org/fhir/Patient?gender=male&_count=20&address-city=Deerfield
  ['male','female'].each do |gender|
    it "filters by gender (#{gender}) and city" do
      skip 'No city found in first page of patients. Try passing in city in command line arg.' if @city.nil?

      response = @client.search(FHIR::Patient, search: {parameters: {'gender' => gender, 'address-city' => @city}})
      assert_response_ok(response)
      assert_bundle_response(response)
      skip "No search results for #{response.request[:url]} makes it hard to to evaluate" if response.resource.entry.empty?
      assert response.resource.entry.all?{|entry| entry.resource.address.any?{|a| a.city.downcase === @city.downcase}}, "Not all responses were in city #{@city}: #{response.request[:url]}"
      assert response.resource.entry.all?{|entry| entry.resource.gender.downcase == gender.downcase}, "Not all matches were gender #{gender}: #{response.request[:url]}"

    end
  end

  # https://syntheticmass.mitre.org/fhir/Patient?condition-code=44054006&_count=20&address-city=Canton
  # https://syntheticmass.mitre.org/fhir/Patient?condition-code=56876005%2C266707007&_count=20&address-city=Canton
  # https://syntheticmass.mitre.org/fhir/Patient?condition-code=230690007%2C53741008%2C22298006%2C410429000%2C49436004%2C49601007&_count=20&address-city=Rutland
  it "filters patients by condition code and address-city" do
    response = @client.search(FHIR::Patient, search: {parameters: {'condition-code' => @condition, 'address-city' => @city}})
    assert_response_ok(response)
    assert_bundle_response(response)
    skip "No search results for #{response.request[:url]} makes it hard to to evaluate. Pass in conditions that patients have by command prompt." if response.resource.entry.empty?
    assert response.resource.entry.all?{|entry| entry.resource.address.any?{|a| a.city.downcase === @city.downcase}}, "Not all responses were in city #{@city}: #{response.request[:url]}"
  end

  # https://syntheticmass.mitre.org/fhir/Patient/58b366453425def0f0f7a5ac
  it "supports GET /Patient/{id}" do
    response = @client.read(FHIR::Patient, @patient.id)
    assert_response_ok response
    assert_resource_type(response, FHIR::Patient)
    assert response.resource.id == @patient.id, "Search by Patient ID didnt return a patient with the right id: #{response.request[:url]}"
  end

  # https://syntheticmass.mitre.org/fhir/Observation?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=date&date=gte2008-04-07
  # https://syntheticmass.mitre.org/fhir/AllergyIntolerance?_format=json&_count=500&patient=58b366453425def0f0f7a5ac
  # https://syntheticmass.mitre.org/fhir/Condition?_format=json&_count=500&patient=58b366453425def0f0f7a5ac
  # https://syntheticmass.mitre.org/fhir/Immunization?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=date
  # https://syntheticmass.mitre.org/fhir/MedicationRequest?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=datewritten
  # https://syntheticmass.mitre.org/fhir/Procedure?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=date
  # https://syntheticmass.mitre.org/fhir/Encounter?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=date
  # https://syntheticmass.mitre.org/fhir/CarePlan?_format=json&_count=500&patient=58b366453425def0f0f7a5ac&_sort:desc=date
  # https://syntheticmass.mitre.org/fhir/Observation?patient=58b366503425def0f0f9b41c&code=69453-9
  queries = [{
    resource: :Observation,
    params: {"_sort:desc" => "date"},
  },{
    resource: :AllergyIntolerance,
    params: {},
  },{
    resource: :Condition,
    params: {},
  },{
    resource: :Immunization,
    params: {"_sort:desc" => "date"},
  },{
    resource: :MedicationRequest,
    params: {"_sort:desc" => "datewritten"},
  },{
    resource: :Procedure,
    params: {"_sort:desc" => "date"},
  },{
    resource: :Encounter,
    params: {"_sort:desc" => "date"},
  },{
    resource: :CarePlan,
    params: {"_sort:desc" => "date"},
  },{
    description: "(Cause of death)",
    resource: :Observation, # CAUSE OF DEATH
    params: {"code" => "69453-9"},
  }]

  queries.each do |q|
    it "can search for patients related #{q[:resource].to_s}" do
      response = @client.search("FHIR::#{q[:resource]}".constantize, search: {parameters: q[:params].merge({"patient" => @patient.id, "_count" => 500})})
      assert_response_ok(response)
      assert_bundle_response(response)
      skip "No search results for #{response.request[:url]} #{q[:description] unless q[:description].nil?} makes it hard to to evaluate. You can pass in an explicit argument -p PATIENTID with a complete patient instead of having this guess" if response.resource.entry.empty?

    end

  end

end

