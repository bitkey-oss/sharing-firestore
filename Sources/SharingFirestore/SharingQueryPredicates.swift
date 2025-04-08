import Foundation

/// Represents query conditions for Firestore.
/// This enum allows you to construct conditions for filtering, ordering, and limiting Firestore data.
///
/// Example:
/// ```swift
/// let predicates: [SharingQueryPredicates] = [
///   .isEqualTo("status", .string("active")),
///   .orderBy("createdAt", true)
/// ]
/// ```
public enum SharingQueryPredicates: @unchecked Sendable, Hashable, Equatable {
  /// Evaluates if a field is equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isEqualTo(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if a field is not equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isNotEqualTo(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if a field is contained in a specified set of values.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - values: Array of values to check against
  case isIn(_ field: String, _ values: [FirestoreQueryData])

  /// Evaluates if a field is not contained in a specified set of values.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - values: Array of values to check against
  case isNotIn(_ field: String, _ values: [FirestoreQueryData])

  /// Evaluates if an array field contains a specified value.
  /// - Parameters:
  ///   - field: The name of the array field to evaluate
  ///   - value: The value to search for
  case arrayContains(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if an array field contains any of the specified values.
  /// - Parameters:
  ///   - field: The name of the array field to evaluate
  ///   - values: Array of values to search for
  case arrayContainsAny(_ field: String, _ values: [FirestoreQueryData])

  /// Evaluates if a field is less than a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isLessThan(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if a field is greater than a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isGreaterThan(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if a field is less than or equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isLessThanOrEqualTo(_ field: String, _ value: FirestoreQueryData)

  /// Evaluates if a field is greater than or equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  case isGreaterThanOrEqualTo(_ field: String, _ value: FirestoreQueryData)

  /// Orders query results by the specified field.
  /// - Parameters:
  ///   - field: The name of the field to order by
  ///   - isDesc: True for descending order, false for ascending order
  case orderBy(_ field: String, _ isDesc: Bool)

  /// Combines multiple conditions with OR operators.
  /// - Parameter predicates: Array of conditions to combine
  indirect case or([SharingQueryPredicates])

  /// Combines multiple conditions with AND operators.
  /// - Parameter predicates: Array of conditions to combine
  indirect case and([SharingQueryPredicates])

  /// Limits query results to the specified count.
  /// - Parameter value: Maximum number of documents to retrieve
  case limitTo(_ value: Int)

  /// Limits query results to the specified count, retrieving from the end of the query.
  /// - Parameter value: Maximum number of documents to retrieve
  case limitToLast(_ value: Int)
}

/// Represents data types that can be used in Firestore queries.
/// This enum handles the conversion between Swift native data types and Firestore data types.
public enum FirestoreQueryData: Hashable, Equatable {
  /// Integer value
  case integer(Int)
  /// Double-precision floating point value
  case float(Double)
  /// String value
  case string(String)
  /// Binary data value
  case data(Data)
  /// Date value
  case date(Date)
  /// Boolean value
  case bool(Bool)
  /// Null value
  case null

  /// Returns the Swift native type value.
  /// Used when passing to the Firestore API.
  public var swiftValue: Any {
    switch self {
    case .integer(let int):
      return int
    case .float(let double):
      return double
    case .string(let string):
      return string
    case .data(let data):
      return data
    case .date(let date):
      return date
    case .bool(let bool):
      return bool
    case .null:
      return NSNull()
    }
  }
}

extension SharingQueryPredicates {
  /// Collection of factory methods for Firestore queries.
  /// These methods help create queries in a form closer to the native Firestore API.

  /// Creates a condition that evaluates if a field is equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isEqualTo value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isEqualTo(field, value)
  }

  /// Creates a condition that evaluates if a field is not equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isNotEqualTo value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isNotEqualTo(field, value)
  }

  /// Creates a condition that evaluates if a field is contained in a specified set of values.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - values: Array of values to check against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isIn values: [FirestoreQueryData])
    -> SharingQueryPredicates
  {
    .isIn(field, values)
  }

  /// Creates a condition that evaluates if a field is not contained in a specified set of values.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - values: Array of values to check against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isNotIn values: [FirestoreQueryData])
    -> SharingQueryPredicates
  {
    .isNotIn(field, values)
  }

  /// Creates a condition that evaluates if an array field contains a specified value.
  /// - Parameters:
  ///   - field: The name of the array field to evaluate
  ///   - value: The value to search for
  /// - Returns: A query condition
  public static func whereField(_ field: String, arrayContains value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .arrayContains(field, value)
  }

  /// Creates a condition that evaluates if an array field contains any of the specified values.
  /// - Parameters:
  ///   - field: The name of the array field to evaluate
  ///   - values: Array of values to search for
  /// - Returns: A query condition
  public static func whereField(
    _ field: String,
    arrayContainsFirestoreAny values: [FirestoreQueryData]
  ) -> SharingQueryPredicates {
    .arrayContainsAny(field, values)
  }

  /// Creates a condition that evaluates if a field is less than a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isLessThan value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isLessThan(field, value)
  }

  /// Creates a condition that evaluates if a field is greater than a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(_ field: String, isGreaterThan value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isGreaterThan(field, value)
  }

  /// Creates a condition that evaluates if a field is less than or equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(
    _ field: String,
    isLessThanOrEqualTo value: FirestoreQueryData
  ) -> SharingQueryPredicates {
    .isLessThanOrEqualTo(field, value)
  }

  /// Creates a condition that evaluates if a field is greater than or equal to a specified value.
  /// - Parameters:
  ///   - field: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func whereField(
    _ field: String,
    isGreaterThanOrEqualTo value: FirestoreQueryData
  ) -> SharingQueryPredicates {
    .isGreaterThanOrEqualTo(field, value)
  }

  /// Creates a condition that orders query results by the specified field.
  /// - Parameters:
  ///   - field: The name of the field to order by
  ///   - value: True for descending order, false for ascending order (default is false)
  /// - Returns: A query condition
  public static func order(by field: String, descending value: Bool = false)
    -> SharingQueryPredicates
  {
    .orderBy(field, value)
  }

  /// Creates a condition that limits query results to the specified count.
  /// - Parameter value: Maximum number of documents to retrieve
  /// - Returns: A query condition
  public static func limit(to value: Int) -> SharingQueryPredicates {
    .limitTo(value)
  }

  /// Creates a condition that limits query results to the specified count, retrieving from the end of the query.
  /// - Parameter value: Maximum number of documents to retrieve
  /// - Returns: A query condition
  public static func limit(toLast value: Int) -> SharingQueryPredicates {
    .limitToLast(value)
  }

  // Alternate naming

  /// Creates a condition using `where` syntax that evaluates if a field is equal to a specified value.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isEqualTo value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isEqualTo(name, value)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is contained in a specified set of values.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - values: Array of values to check against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isIn values: [FirestoreQueryData])
    -> SharingQueryPredicates
  {
    .isIn(name, values)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is not contained in a specified set of values.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - values: Array of values to check against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isNotIn values: [FirestoreQueryData])
    -> SharingQueryPredicates
  {
    .isNotIn(name, values)
  }

  /// Creates a condition using `where` syntax that evaluates if an array field contains a specified value.
  /// - Parameters:
  ///   - name: The name of the array field to evaluate
  ///   - value: The value to search for
  /// - Returns: A query condition
  public static func `where`(field name: String, arrayContains value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .arrayContains(name, value)
  }

  /// Creates a condition using `where` syntax that evaluates if an array field contains any of the specified values.
  /// - Parameters:
  ///   - name: The name of the array field to evaluate
  ///   - values: Array of values to search for
  /// - Returns: A query condition
  public static func `where`(_ name: String, arrayContainsFirestoreAny values: [FirestoreQueryData])
    -> SharingQueryPredicates
  {
    .arrayContainsAny(name, values)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is less than a specified value.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isLessThan value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isLessThan(name, value)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is greater than a specified value.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isGreaterThan value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isGreaterThan(name, value)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is less than or equal to a specified value.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func `where`(_ name: String, isLessThanOrEqualTo value: FirestoreQueryData)
    -> SharingQueryPredicates
  {
    .isLessThanOrEqualTo(name, value)
  }

  /// Creates a condition using `where` syntax that evaluates if a field is greater than or equal to a specified value.
  /// - Parameters:
  ///   - name: The name of the field to evaluate
  ///   - value: The value to compare against
  /// - Returns: A query condition
  public static func `where`(
    _ name: String,
    isGreaterThanOrEqualTo value: FirestoreQueryData
  ) -> SharingQueryPredicates {
    .isGreaterThanOrEqualTo(name, value)
  }
}
