# referensed from bug664-1.patch
# https://gist.github.com/benjaminvialle/4055208
require 'spec_helper'

describe 'Routing to main page', :type => :routing do
  context 'Locale-less root' do
    it 'routes / to login' do
      expect(:get => "/").to route_to(
        :controller => 'main',
        :action => 'login'
      )
    end
  end
  
  
  context 'Root with locale' do
    it 'routes /en/ to error' do
      expect(:get => "/en/").not_to be_routable
    end
  end
end

context 'Admin resource' do
  
    let(:admin) { create(:admin) }
    let(:path) { '/en/admins' }
    let(:ctrl) { 'admins' }

  
  it 'routes GET index correctly' do
    expect(:get => path).to route_to(
      :controller => ctrl,
      :action => 'index',
      :locale => 'en')
  end
  
  it 'routes GET new correctly' do
    expect(:get => path + '/new').to route_to(
      :controller => ctrl,
      :action => 'new',
      :locale => 'en')
  end
  
  it 'routes POST create correctly' do
    expect(:post => path).to route_to(
      :controller => ctrl,
      :action => 'create',
      :locale => 'en')
  end
  
  it 'routes GET show correctly' do
    expect(:get => path + '/' + admin.id.to_s).to route_to(
      :controller => ctrl,
      :action => 'show',
      :id => admin.id.to_s,
      :locale => 'en')
  end
  
  it 'routes GET edit correctly' do
    expect(:get => path + '/' + admin.id.to_s + '/edit').to route_to(
      :controller => ctrl,
      :action => 'edit',
      :id => admin.id.to_s,
      :locale => 'en')
  end
  
end
