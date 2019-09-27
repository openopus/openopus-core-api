class ModelsApi < Openopus::Core::Api::BaseApi
  on '/test_api' do
    expose Organization
  end
end
