
require 'broken_links'
describe BrokenLinks::Crawler do
  it "find is gross" do
    expect(BrokenLinks::Crawler.find).to eql("sabelo")
  end
end
