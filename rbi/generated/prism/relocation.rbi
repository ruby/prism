# typed: true

module Prism
  # Prism parses deterministically for the same input. This provides a nice
  # property that is exposed through the #node_id API on nodes. Effectively this
  # means that for the same input, these values will remain consistent every
  # time the source is parsed. This means we can reparse the source same with a
  # #node_id value and find the exact same node again.
  #
  # The Relocation module provides an API around this property. It allows you to
  # "save" nodes and locations using a minimal amount of memory (just the
  # node_id and a field identifier) and then reify them later.
  module Relocation
    # An entry in a repository that will lazily reify its values when they are
    # first accessed.
    class Entry
      # Raised if a value that could potentially be on an entry is missing
      # because it was either not configured on the repository or it has not yet
      # been fetched.
      class MissingValueError < StandardError; end

      # Initialize a new entry with the given repository.
      sig { params(repository: Repository).void }
      def initialize(repository); end

      # Fetch the filepath of the value.
      sig { returns(String) }
      def filepath; end

      # Fetch the start line of the value.
      sig { returns(Integer) }
      def start_line; end

      # Fetch the end line of the value.
      sig { returns(Integer) }
      def end_line; end

      # Fetch the start byte offset of the value.
      sig { returns(Integer) }
      def start_offset; end

      # Fetch the end byte offset of the value.
      sig { returns(Integer) }
      def end_offset; end

      # Fetch the start character offset of the value.
      sig { returns(Integer) }
      def start_character_offset; end

      # Fetch the end character offset of the value.
      sig { returns(Integer) }
      def end_character_offset; end

      # Fetch the start code units offset of the value, for the encoding that
      # was configured on the repository.
      sig { returns(Integer) }
      def start_code_units_offset; end

      # Fetch the end code units offset of the value, for the encoding that was
      # configured on the repository.
      sig { returns(Integer) }
      def end_code_units_offset; end

      # Fetch the start byte column of the value.
      sig { returns(Integer) }
      def start_column; end

      # Fetch the end byte column of the value.
      sig { returns(Integer) }
      def end_column; end

      # Fetch the start character column of the value.
      sig { returns(Integer) }
      def start_character_column; end

      # Fetch the end character column of the value.
      sig { returns(Integer) }
      def end_character_column; end

      # Fetch the start code units column of the value, for the encoding that
      # was configured on the repository.
      sig { returns(Integer) }
      def start_code_units_column; end

      # Fetch the end code units column of the value, for the encoding that was
      # configured on the repository.
      sig { returns(Integer) }
      def end_code_units_column; end

      # Fetch the leading comments of the value.
      sig { returns(T::Array[CommentsField::Comment]) }
      def leading_comments; end

      # Fetch the trailing comments of the value.
      sig { returns(T::Array[CommentsField::Comment]) }
      def trailing_comments; end

      # Fetch the leading and trailing comments of the value.
      sig { returns(T::Array[CommentsField::Comment]) }
      def comments; end

      # Reify the values on this entry with the given values. This is an
      # internal-only API that is called from the repository when it is time to
      # reify the values.
      sig { params(values: T::Hash[Symbol, T.untyped]).void }
      def reify!(values); end

      # Fetch a value from the entry, raising an error if it is missing.
      sig { params(name: Symbol).returns(T.untyped) }
      private def fetch_value(name); end

      # Return the values from the repository, reifying them if necessary.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      private def values; end
    end

    # Represents the source of a repository that will be reparsed.
    class Source
      # The value that will need to be reparsed.
      sig { returns(T.untyped) }
      attr_reader :value

      # Initialize the source with the given value.
      sig { params(value: T.untyped).void }
      def initialize(value); end

      # Reparse the value and return the parse result.
      sig { returns(ParseResult) }
      def result; end

      # Create a code units cache for the given encoding.
      sig { params(encoding: Encoding).returns(T.untyped) }
      def code_units_cache(encoding); end
    end

    # A source that is represented by a file path.
    class SourceFilepath < Source
      # Reparse the file and return the parse result.
      sig { returns(ParseResult) }
      def result; end
    end

    # A source that is represented by a string.
    class SourceString < Source
      # Reparse the string and return the parse result.
      sig { returns(ParseResult) }
      def result; end
    end

    # A field that represents the file path.
    class FilepathField
      # The file path that this field represents.
      sig { returns(String) }
      attr_reader :value

      # Initialize a new field with the given file path.
      sig { params(value: String).void }
      def initialize(value); end

      # Fetch the file path.
      sig { params(_value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(_value); end
    end

    # A field representing the start and end lines.
    class LinesField
      # Fetches the start and end line of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the start and end byte offsets.
    class OffsetsField
      # Fetches the start and end byte offset of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the start and end character offsets.
    class CharacterOffsetsField
      # Fetches the start and end character offset of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the start and end code unit offsets.
    class CodeUnitOffsetsField
      # A pointer to the repository object that is used for lazily creating a
      # code units cache.
      sig { returns(Repository) }
      attr_reader :repository

      # The associated encoding for the code units.
      sig { returns(Encoding) }
      attr_reader :encoding

      # Initialize a new field with the associated repository and encoding.
      sig { params(repository: Repository, encoding: Encoding).void }
      def initialize(repository, encoding); end

      # Fetches the start and end code units offset of a value for a particular
      # encoding.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end

      # Lazily create a code units cache for the associated encoding.
      sig { returns(T.untyped) }
      private def cache; end
    end

    # A field representing the start and end byte columns.
    class ColumnsField
      # Fetches the start and end byte column of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the start and end character columns.
    class CharacterColumnsField
      # Fetches the start and end character column of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the start and end code unit columns for a specific
    # encoding.
    class CodeUnitColumnsField
      # The repository object that is used for lazily creating a code units
      # cache.
      sig { returns(Repository) }
      attr_reader :repository

      # The associated encoding for the code units.
      sig { returns(Encoding) }
      attr_reader :encoding

      # Initialize a new field with the associated repository and encoding.
      sig { params(repository: Repository, encoding: Encoding).void }
      def initialize(repository, encoding); end

      # Fetches the start and end code units column of a value for a particular
      # encoding.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end

      # Lazily create a code units cache for the associated encoding.
      sig { returns(T.untyped) }
      private def cache; end
    end

    # An abstract field used as the parent class of the two comments fields.
    class CommentsField
      # An object that represents a slice of a comment.
      class Comment
        # The slice of the comment.
        sig { returns(String) }
        attr_reader :slice

        # Initialize a new comment with the given slice.
        #
        sig { params(slice: String).void }
        def initialize(slice); end
      end

      # Create comment objects from the given values.
      sig { params(values: T.untyped).returns(T::Array[Comment]) }
      private def comments(values); end
    end

    # A field representing the leading comments.
    class LeadingCommentsField < CommentsField
      # Fetches the leading comments of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A field representing the trailing comments.
    class TrailingCommentsField < CommentsField
      # Fetches the trailing comments of a value.
      sig { params(value: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def fields(value); end
    end

    # A repository is a configured collection of fields and a set of entries
    # that knows how to reparse a source and reify the values.
    class Repository
      # Raised when multiple fields of the same type are configured on the same
      # repository.
      class ConfigurationError < StandardError; end

      # The source associated with this repository. This will be either a
      # SourceFilepath (the most common use case) or a SourceString.
      sig { returns(Source) }
      attr_reader :source

      # The fields that have been configured on this repository.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :fields

      # The entries that have been saved on this repository.
      sig { returns(T::Hash[Integer, T::Hash[Symbol, Entry]]) }
      attr_reader :entries

      # Initialize a new repository with the given source.
      sig { params(source: Source).void }
      def initialize(source); end

      # Create a code units cache for the given encoding from the source.
      sig { params(encoding: Encoding).returns(T.untyped) }
      def code_units_cache(encoding); end

      # Configure the filepath field for this repository and return self.
      sig { returns(T.self_type) }
      def filepath; end

      # Configure the lines field for this repository and return self.
      sig { returns(T.self_type) }
      def lines; end

      # Configure the offsets field for this repository and return self.
      sig { returns(T.self_type) }
      def offsets; end

      # Configure the character offsets field for this repository and return
      # self.
      sig { returns(T.self_type) }
      def character_offsets; end

      # Configure the code unit offsets field for this repository for a specific
      # encoding and return self.
      sig { params(encoding: Encoding).returns(T.self_type) }
      def code_unit_offsets(encoding); end

      # Configure the columns field for this repository and return self.
      sig { returns(T.self_type) }
      def columns; end

      # Configure the character columns field for this repository and return
      # self.
      sig { returns(T.self_type) }
      def character_columns; end

      # Configure the code unit columns field for this repository for a specific
      # encoding and return self.
      sig { params(encoding: Encoding).returns(T.self_type) }
      def code_unit_columns(encoding); end

      # Configure the leading comments field for this repository and return
      # self.
      sig { returns(T.self_type) }
      def leading_comments; end

      # Configure the trailing comments field for this repository and return
      # self.
      sig { returns(T.self_type) }
      def trailing_comments; end

      # Configure both the leading and trailing comment fields for this
      # repository and return self.
      sig { returns(T.self_type) }
      def comments; end

      # This method is called from nodes and locations when they want to enter
      # themselves into the repository. It it internal-only and meant to be
      # called from the #save* APIs.
      sig { params(node_id: Integer, field_name: Symbol).returns(Entry) }
      def enter(node_id, field_name); end

      # This method is called from the entries in the repository when they need
      # to reify their values. It is internal-only and meant to be called from
      # the various value APIs.
      sig { void }
      def reify!; end

      # Append the given field to the repository and return the repository so
      # that these calls can be chained.
      sig { params(name: Symbol, arg0: T.untyped).returns(T.self_type) }
      private def field(name, arg0); end
    end

    # Create a new repository for the given filepath.
    sig { params(value: String).returns(Repository) }
    def self.filepath(value); end

    # Create a new repository for the given string.
    sig { params(value: String).returns(Repository) }
    def self.string(value); end
  end
end
