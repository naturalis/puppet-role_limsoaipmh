require 'spec_helper'
describe 'limsoaipmh' do

  context 'with defaults for all parameters' do
    it { should contain_class('limsoaipmh') }
  end
end
