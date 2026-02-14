require 'rails_helper'
require 'webmock/rspec'

RSpec.describe PrefabClient do
  let(:client) { PrefabClient.new }

  describe '#homes' do
    it 'returns homes on success' do
      stub_request(:get, 'http://localhost:8080/homes').to_return(status: 200, body: '[{"id": 1}]')
      expect(client.homes).to eq([{id: 1}])
    end

    it 'returns [] on connection error' do
      allow(HTTParty).to receive(:get).and_raise(Errno::ECONNREFUSED)
      expect(client.homes).to eq([])
      expect(Rails.logger).to have_received(:error).with(/PrefabClient error: Connection refused/)
    end

    it 'returns [] on 500 error' do
      stub_request(:get, 'http://localhost:8080/homes').to_return(status: 500)
      expect(client.homes).to eq([])
      expect(Rails.logger).to have_received(:error).with(/PrefabClient error: Non-200 response: 500/)
    end

    it 'handles URL encoding' do
      stub_request(:get, 'http://localhost:8080/homes').to_return(status: 200, body: '[{"name": "Mom\'s House"}]')
      expect(client.homes).to eq([{name: "Mom's House"}])
    end
  end

  describe '#rooms' do
    it 'uses URL encoding for home name' do
      stub_request(:get, 'http://localhost:8080/rooms/Mom%27s%20House').to_return(status: 200, body: '[{"name": "Living Room"}]')
      expect(client.rooms("Mom's House")).to eq([{name: "Living Room"}])
    end
  end

  describe '#accessories' do
    it 'uses URL encoding for home and room' do
      stub_request(:get, 'http://localhost:8080/accessories/Mom%27s%20House/Living%20Room%20%232').to_return(status: 200, body: '[{"name": "Light"}]')
      expect(client.accessories("Mom's House", "Living Room #2")).to eq([{name: "Light"}])
    end
  end

  describe '#scenes' do
    it 'uses ENV override' do
      allow(ENV).to receive(:[]).with('PREFAB_API_URL').and_return('http://custom:8080')
      stub_request(:get, 'http://custom:8080/scenes/Home').to_return(status: 200, body: '[{"name": "Good Morning"}]')
      expect(client.scenes('Home')).to eq([{name: "Good Morning"}])
    end
  end

  describe '#get' do
    it 'times out after 5 seconds' do
      allow(HTTParty).to receive(:get).and_raise(Timeout::Error)
      expect(client.homes).to eq([])
      expect(Rails.logger).to have_received(:error).with(/PrefabClient error: execution expired/)
    end
  end
end