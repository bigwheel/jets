# There was a bug that prepending action modified the global callbacks array throwing a lot of
# errors in this spec and others
#
# If you see unwanted :prepended actions in your callback, it means that prepend_* methods are
# modifying the global callbacks table.
class PrependBeforeBugController < Jets::Controller::Base
  prepend_before_action :prepended
  def prepended; end
end

class PrependAfterBugController < Jets::Controller::Base
  prepend_after_action :prepended
  def prepended; end
end

class FakeController < Jets::Controller::Base
  before_action :find_article
  def find_article; end
end

class WhateverController < Jets::Controller::Base
  before_action :find_whatever
  def find_whatever; end
end

class BreakableController < Jets::Controller::Base
  before_action :breakable_action
  before_action :another_action

  def index
    raise "should not get here"
  end

  def breakable_action
    render json: {}, status: 404
  end

  def another_action
    raise "should not get here"
  end
end

class PrependAppendBeforeController < Jets::Controller::Base
  append_before_action :normal
  prepend_before_action :prepended

  def normal; end
  def prepended; end
end

class PrependAppendAfterController < Jets::Controller::Base
  append_after_action :normal
  prepend_after_action :prepended

  def normal; end
  def prepended; end
end

class SkippedBeforeController < Jets::Controller::Base
  before_action :first
  before_action :second
  skip_before_action :first

  def first; end
  def second; end
end

class SkippedBeforeWithOnlyController < Jets::Controller::Base
  before_action :first
  skip_before_action :first, only: %i[index]

  def first; end
  def index; end
end


class SkippedAfterController < Jets::Controller::Base
  after_action :first
  after_action :second
  skip_after_action :first

  def first; end
  def second; end
end

describe Jets::Controller::Base do
  context FakeController do
    let(:controller) { FakeController.new({}, nil, "meth") }

    it "before_actions includes find_article only" do
      expect(controller.class.before_actions).to eq [[:find_article, {}]]
    end
  end

  context WhateverController do
    let(:controller) { WhateverController.new({}, nil, "meth") }

    it "before_actions includes find_whatever only" do
      expect(controller.class.before_actions).to eq [[:find_whatever, {}]]
    end
  end

  context BreakableController do
    let(:controller) { BreakableController.new({}, nil, :index) }

    it "breaks before reaching index" do
      response = controller.dispatch!
      expect(response[0]).to eq '404'
      expect(response[2].read).to eq '{}'
    end
  end

  context PrependAppendBeforeController do
    subject { PrependAppendBeforeController.new({}, nil, :index) }
    it "prepends method" do
      expect(subject.class.before_actions).to eq [[:prepended, {}], [:normal, {}]]
    end
  end

  context PrependAppendAfterController do
    subject { PrependAppendAfterController.new({}, nil, :index) }
    it "prepends method" do
      expect(subject.class.after_actions).to eq [[:prepended, {}], [:normal, {}]]
    end
  end

  context SkippedBeforeController do
    subject { SkippedBeforeController.new({}, nil, :index) }
    it "skips method" do
      expect(subject.class.before_actions).to eq [[:second, {}]]
    end
  end

  context SkippedBeforeWithOnlyController do
    subject { SkippedBeforeWithOnlyController.new({}, nil, :index) }
    it "adds the method to the except of the callback" do
      expect(subject.class.before_actions).to eq [[:first, {except: [:index]}]]
    end
  end

  context SkippedAfterController do
    subject { SkippedAfterController.new({}, nil, :index) }
    it "skips method" do
      expect(subject.class.after_actions).to eq [[:second, {}]]
    end
  end
end
