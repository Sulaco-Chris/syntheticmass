describe 'Server (Datathon Requirements)' do 

  include Crucible::Tests::Assertions

  url = RSpec.configuration.fhir_url

  before(:all) do
    @client = FHIR::Client.new(url)
    @client.default_json
  end

  # TODO


end

