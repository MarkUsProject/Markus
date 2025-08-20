describe 'routing' do
  Rails.application.routes.routes.map do |r|
    spec = r.path.spec.to_s
    next if %r{^/rails|^/assets|^/cable|.*\*path\(.:format\)}.match?(spec)
    r.verb.split('|').each do |verb|
      it "#{verb}: #{r.path.spec}" do
        parts = r.required_parts.index_with { |_part| '1' }
        path = r.path.build_formatter.evaluate(parts)
        expect(verb.downcase => path).to route_to(**r.defaults, **parts)
      end
    end
  end

  describe 'root with locale' do
    it 'routes /en/ to error' do
      expect(get: '/en/').to route_to(controller: 'main', action: 'page_not_found', path: 'en')
    end
  end
end
