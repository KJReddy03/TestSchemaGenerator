# JSON → Hive Generator

A powerful Dart code generator that automatically converts JSON schema definitions into Hive database models.

## Features

### Flexible Input Formats

The generator supports three different input formats to accommodate various use cases:

#### 1. Full Schema Format (Recommended for Production)

Complete schema with table name, typeId, field definitions, and sample data:

```json
{
  "table": "customers",
  "typeId": 1,
  "fields": {
    "id": { "type": "int", "required": true },
    "name": { "type": "string", "required": true },
    "email": { "type": "string", "nullable": true },
    "created_at": { "type": "datetime", "default": "DateTime.now()" }
  },
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 2. Schema-Only Format

Just the field definitions - table name and typeId are auto-derived from filename:

```json
{
  "fields": {
    "id": { "type": "string", "nullable": true },
    "orgId": { "type": "string", "required": true },
    "facilityId": { "type": "string", "required": true },
    "invoiceNumber": { "type": "string", "required": true },
    "totalAmount": { "type": "double", "required": true },
    "invoiceDate": { "type": "datetime", "required": true }
  }
}
```

#### 3. Data-Only Format

Just sample data - fields, types, and table name are auto-detected:

```json
[
  {
    "id": "inv-001",
    "orgId": "org-123",
    "facilityId": "fac-456",
    "invoiceNumber": "INV-2024-001",
    "totalAmount": 150.75,
    "invoiceDate": "2024-01-15T10:30:00Z"
  }
]
```

### Auto-Detection Features

- **Type Detection**: Automatically infers types from data:
  - Numeric values without decimals → `int`
  - Numeric values with decimals → `double`
  - `true`/`false` strings → `bool`
  - ISO 8601 datetime strings → `DateTime`
  - Other values → `string`

- **Table Name Derivation**: Auto-generates from filename:
  - `customer.json` → `customers` table
  - `order_item.json` → `order_items` table

- **TypeId Assignment**: Automatically assigns typeIds:
  - `customers` → typeId: 1
  - `orders` → typeId: 2
  - Other tables → typeId: 3

- **Field Schema Generation**: Creates complete field schemas with nullability, requirements, and defaults
  "typeId": 1,
  "fields": {
  "id": "int",
  "name": "string",
  "email": "string"
  },
  "data": [...]
  }

## Quick Start

### 1. Install Dependencies

```bash
dart pub get
```

### 2. Run the Generator

```bash
dart generator/db_generator.dart
```

This scans `json_models/` and generates Hive models in the `generated/` folder, including the Hive TypeAdapters (`.g.dart` files).

### 3. Run Tests

```bash
dart test
```

### 4. Use Generated Models

Import and use the generated models in your application:

```dart
import 'generated/customer_model.dart';

// Create an instance
final customer = Customer(
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
  created_at: DateTime.now(),
);

// Save to Hive
final box = await Hive.openBox<Customer>('customers');
await box.put('customer_1', customer);
```

---

## Project Structure

```
json_hive_generator/
├── json_models/              # Input: JSON schema definitions
│   ├── customer.json
│   └── orders.json
├── generator/                # Generator script
│   └── db_generator.dart
├── generated/                # Output: Generated Dart models
│   ├── customer_model.dart
│   └── order_model.dart
├── test/                     # Test suite
│   ├── generator_test.dart
│   └── integration_test.dart
├── pubspec.yaml              # Dependencies
└── IMPLEMENTATION_REPORT.md  # Detailed report
```

---

## JSON Schema Format

The generator is extremely flexible and accepts three different JSON formats:

### Format 1: Full Schema (Most Control)

```json
{
  "table": "customers",
  "typeId": 1,
  "fields": {
    "id": {"type": "int", "required": true},
    "name": {"type": "string", "required": true},
    "email": {"type": "string", "nullable": true},
    "created_at": {"type": "datetime", "default": "DateTime.now()"}
  },
  "data": [...]
}
```

### Format 2: Schema-Only (Medium Control)

```json
{
  "fields": {
    "id": { "type": "string", "nullable": true },
    "name": { "type": "string", "required": true }
  }
}
```

### Format 3: Data-Only (Least Control, Most Convenience)

```json
[
  {
    "id": "cust-001",
    "name": "John Doe",
    "email": "john@example.com"
  }
]
```

### Field Definition Properties

| Property | Type    | Description                              | Example                   |
| -------- | ------- | ---------------------------------------- | ------------------------- |
| type     | string  | Field data type                          | `"string"`, `"int"`       |
| nullable | boolean | Whether field can be null                | `true`, `false`           |
| required | boolean | Whether field is required in constructor | `true`, `false`           |
| default  | any     | Default value for optional fields        | `0`, `"default"`, `false` |
| model    | string  | Model name for objects/lists             | `"OrderItem"`             |

### Supported Types

| JSON Type                 | Dart Type    | Example                    |
| ------------------------- | ------------ | -------------------------- |
| int, integer              | int          | `"age": "int"`             |
| double, float             | double       | `"price": "double"`        |
| bool, boolean             | bool         | `"active": "bool"`         |
| string, text              | String       | `"name": "string"`         |
| datetime, date, timestamp | DateTime     | `"created_at": "datetime"` |
| object                    | Custom Class | `"details": "object"`      |
| list                      | List         | `"tags": "list"`           |

---

## Generated Model Example

**Input:** `json_models/customer.json`

```json
{
  "table": "customers",
  "typeId": 1,
  "fields": {
    "id": "int",
    "name": "string",
    "email": "string",
    "created_at": "datetime"
  }
}
```

**Output:** `generated/customer_model.dart`

```dart
import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 1)
class Customer extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final DateTime created_at;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.created_at,
  });
}
```

---

## Generator Functions

### DbGenerator Class

- **main()** - Entry point; scans json_models/ and generates models
- **\_processJsonFile()** - Reads and processes individual JSON schemas
- **\_generateHiveModel()** - Creates Dart class code with Hive annotations
- **\_mapType()** - Converts JSON types to Dart types
- **\_toPascalCase()** - Converts snake_case to PascalCase
- **\_toSnakeCase()** - Converts PascalCase to snake_case

---

## Testing

### Unit Tests

```bash
dart test test/generator_test.dart
```

Tests:

- JSON schema validation
- Generator function existence
- Generated model structure
- Annotation correctness
- Case conversion utilities

### Integration Tests

```bash
dart test test/integration_test.dart
```

Demonstrates:

- Hive initialization
- Model instance creation
- Data persistence
- Data retrieval

### Run All Tests

```bash
dart test
```

---

## Workflow Examples

### Example 1: Add a New Table

1. Create `json_models/products.json`:

```json
{
  "table": "products",
  "typeId": 3,
  "fields": {
    "id": "int",
    "name": "string",
    "price": "double",
    "stock": "int"
  }
}
```

2. Run generator:

```bash
dart generator/db_generator.dart
```

3. Generated file: `generated/product_model.dart`

### Example 2: Update an Existing Schema

1. Modify `json_models/customer.json` (add a field)
2. Run generator
3. Generated model automatically updated

---

## Integration with Flutter

For Flutter projects:

1. Copy the `generator/` and `json_models/` folders to your Flutter project
2. Run `flutter pub get`
3. Generate models: `dart generator/db_generator.dart`
4. Generate adapters: `flutter pub run build_runner build`
5. Use as normal Hive models

---

## Limitations & Notes

- Nested objects are not supported (use Map type if needed)
- Arrays need to be defined as "list" type
- TypeIDs must be unique across all models
- Requires Dart 2.17 or later

---

## Performance

- **Generation Speed**: < 1 second for multiple schemas
- **Generated Code Size**: ~400 bytes per model
- **Runtime Overhead**: Minimal (generated code is static)

---

## Troubleshooting

### Generator Not Creating Files

- Check `json_models/` directory exists
- Verify JSON syntax is valid
- Check permissions for `generated/` directory

### Import Errors

- Run `dart pub get` to ensure dependencies are installed
- Check generated file paths are correct
- Verify @HiveType decorators have unique typeId values

### Test Failures

- Ensure all JSON schemas are valid
- Check that field types are supported
- Verify generator script has write permissions to `generated/`

---

## Support

For issues or questions:

1. Check the JSON schema format
2. Run tests: `dart test`
3. Review `IMPLEMENTATION_REPORT.md` for detailed information

---

## License

This project is provided as-is for educational and development purposes.

---

## Quick Reference

```bash
# Install dependencies
dart pub get

# Run generator
dart generator/db_generator.dart

# Run all tests
dart test

# Run specific test
dart test test/integration_test.dart

# Format code
dart format .

# Check for issues
dart analyze
```

---

**Happy Hive database modeling! 🚀**
