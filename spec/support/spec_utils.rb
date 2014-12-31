module SpecUtils
  def fixture_path(filename)
    File.join(SPEC_ROOT, 'fixtures', filename)
  end
end
