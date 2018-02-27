require "test_helper"

class DocsRailwayTest < Minitest::Spec
  module Methods
    def authenticate(ctx, **)

    end
    def auth_err(ctx, **)

    end
    def reset_counter(ctx, **)

    end
    def find_model(ctx, **)

    end
  end

  class RecoverTest < Minitest::Spec
    Memo = Class.new(Memo)

    module Memo::Create
      extend Trailblazer::Activity::Railway()
      #~methods
      extend Methods
      def self.find_by_email(ctx, **)
        true
      end
      #~methods end
      step method(:authenticate)
      fail method(:auth_err), Output(:success) => :find_by_email
      step method(:find_by_email)#, id: "find_by_email"

      step method(:find_model)
    end

    it do
       Cct(Memo::Create.to_h[:circuit], inspect_task: Activity::Introspect.method(:inspect_task_builder)).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.authenticate}>
#<TaskBuilder{.authenticate}>
 {Trailblazer::Activity::Left} => #<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_by_email}>
#<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_by_email}>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<TaskBuilder{.find_by_email}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_model}>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<TaskBuilder{.find_model}>
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<End/:success>

#<End/:failure>
}
    end
  end

  class ThirdTrackTest < Minitest::Spec
    Memo = Class.new(Memo)
    #:custom
    module Memo::Create
      extend Trailblazer::Activity::Railway()
      #~methods
      extend Methods
      #~methods end
      step method(:authenticate),  Output(:failure) => :auth_failed
      step method(:auth_err),      magnetic_to: [:auth_failed], Output(:success) => :auth_failed
      step method(:reset_counter), magnetic_to: [:auth_failed], Output(:success) => End(:authentication_failure)

      step method(:find_model)
    end
    #:custom end

    it do
       Cct(Memo::Create.to_h[:circuit], inspect_task: Activity::Introspect.method(:inspect_task_builder)).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.authenticate}>
#<TaskBuilder{.authenticate}>
 {Trailblazer::Activity::Left} => #<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_model}>
#<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Left} => #<End/:failure>
 {Trailblazer::Activity::Right} => #<End/:authentication_failure>
#<TaskBuilder{.find_model}>
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<End/:success>

#<End/:failure>

#<End/:authentication_failure>
}
    end

  end

  class ThirdTrackWithPathTest < Minitest::Spec
    Memo = Class.new(Memo)
    #:path
    module Memo::Create
      extend Trailblazer::Activity::Railway()
      #~methods
      extend Methods
      #~methods end
      step method(:authenticate), Output(:failure) => Path() do
        task Memo::Create.method(:auth_err)
        task Memo::Create.method(:reset_counter), Output(:success) => End(:authentication_failure)
      end

      step method(:find_model)
    end
    #:path end

    it do
       Cct(Memo::Create.to_h[:circuit], inspect_task: Activity::Introspect.method(:inspect_task_builder)).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.authenticate}>
#<TaskBuilder{.authenticate}>
 {Trailblazer::Activity::Left} => #<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_model}>
#<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Left} => #<End/:failure>
 {Trailblazer::Activity::Right} => #<End/:authentication_failure>
#<TaskBuilder{.find_model}>
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<End/:success>

#<End/:failure>

#<End/\"track_0.\">

#<End/:authentication_failure>
}
    end

  end

  class ThirdTrackWithPathAndImplicitEndTest < Minitest::Spec
    Memo = Class.new(Memo)
    #:path-end
    module Memo::Create
      extend Trailblazer::Activity::Railway()
      #~methods
      extend Methods
      #~methods end
      step method(:authenticate), Output(:failure) => Path( end_semantic: :authentication_failure ) do
        pass Memo::Create.method(:auth_err)
        pass Memo::Create.method(:reset_counter)
      end

      step method(:find_model)
    end
    #:path-end end

    it do
       Cct(Memo::Create.to_h[:circuit], inspect_task: Activity::Introspect.method(:inspect_task_builder)).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.authenticate}>
#<TaskBuilder{.authenticate}>
 {Trailblazer::Activity::Left} => #<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.find_model}>
#<TaskBuilder{.auth_err}>
 {Trailblazer::Activity::Right} => #<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Left} => #<TaskBuilder{.reset_counter}>
#<TaskBuilder{.reset_counter}>
 {Trailblazer::Activity::Right} => #<End/:authentication_failure>
 {Trailblazer::Activity::Left} => #<End/:authentication_failure>
#<TaskBuilder{.find_model}>
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<End/:success>

#<End/:failure>

#<End/:authentication_failure>
}
    end

  end

end


# So, the entire mental model of setting up a complex graph with a linear DSL is based on some super simple algorithm I came up with
# That assumes that very task has "magnetic" inputs, and magnetic outputs
# and that way, you can build more complex graphs super easily, once you get the hang of the "magnetic" model
