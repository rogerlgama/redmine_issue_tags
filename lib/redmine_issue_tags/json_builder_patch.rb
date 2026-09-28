module RedmineIssueTags
  module JsonBuilderPatch
    def output
      RedmineIssueTags.inject_tags_into_standard_api!(@struct.first, @request.path_parameters)
      super
    end
  end
end
