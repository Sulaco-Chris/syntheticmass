describe 'Server (Basic)' do 

  include Crucible::Tests::Assertions

  url = RSpec.configuration.fhir_url
  city = RSpec.configuration.city
  patient = RSpec.configuration.patient

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
  end

  it 'returns valid capability statement (using STU3)' do

    config_statement = @client.capability_statement

    assert config_statement.is_a?(FHIR::CapabilityStatement), "Returns capability statement"

  end

  it 'Supports listing all Patients' do

      response = @client.read_feed(FHIR::Patient) # fetch Bundle of Patients
      assert_response_ok(response)
      assert_bundle_response(response)

  end

  it 'Supports next/previous on Patient search by city' do

    if(city.nil?)
      response = @client.read_feed(FHIR::Patient) # fetch Bundle of Patients
      assert_response_ok(response)
      assert_bundle_response(response)
      city = response.resource.entry.find{|p| !p.try(:resource).try(:address).try(:first).nil?}.try(:resource).try(:address).try(:first).try(:city)
    end

    skip 'Could not easily find any cities to search patients against.  Perhaps pass a known city through command line argument.' if city.nil?

    initial_page = @client.search(FHIR::Patient, search: {parameters: {'address-city' => city, '_count' => 5}})

    assert_bundle_response(initial_page)

    skip "No search results for #{initial_page.request[:url]} makes it hard to to evaluate" if initial_page.resource.entry.empty?

    next_page = @client.next_page(initial_page)

    assert (next_page.resource.entry.map{|e|e.resource.id} & initial_page.resource.entry.map{|e|e.resource.id}).empty?,'Next page contained IDs from initial page'

    previous_page = @client.next_page(next_page, :previous_link)

    assert (next_page.resource.entry.map{|e|e.resource.id} & previous_page.resource.entry.map{|e|e.resource.id}).empty?,'Next page contained IDs from previous page'
    assert (initial_page.resource.entry.map{|e|e.resource.id} - previous_page.resource.entry.map{|e|e.resource.id}).empty?,'Going forward and backwards in page should result in same content.'


  end

  it 'supports $everything operator on Patient' do
    skip 'No patient found automatically, try passing in command line.' if @patient.nil?

    response = @client.fetch_patient_record(@patient.id)
    assert_response_ok(response)
    assert_bundle_response(response)
    assert response.resource.entry.select{|e| e.resource.is_a? FHIR::Patient}.length == 1, "Should get a bundle back with 1 patient record in #{response.request[:url]}"
    assert response.resource.entry.select{|e| !e.resource.is_a? FHIR::Patient}.length >= 1, "Should get a bundle back with at least one non-patient in it in in #{response.request[:url]}"

  end

end

