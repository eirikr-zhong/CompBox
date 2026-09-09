import 'package:comp_box/data/component_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clear removes every component record', () {
    final repository = ComponentRepository.inMemory();
    addTearDown(repository.close);
    repository
      ..save(_record('A-01-01'))
      ..save(_record('B-02-03'));

    repository.clear();

    expect(repository.all(), isEmpty);
    expect(repository.byLocation('A-01-01'), isNull);
    expect(repository.byLocation('B-02-03'), isNull);
  });

  test('delete removes only the record at the requested location', () {
    final repository = ComponentRepository.inMemory();
    addTearDown(repository.close);
    repository
      ..save(_record('A-01-01'))
      ..save(_record('B-02-03'));

    repository.delete('A-01-01');

    expect(repository.byLocation('A-01-01'), isNull);
    expect(repository.byLocation('B-02-03'), isNotNull);
  });

  test('replaceAll atomically replaces every component record', () {
    final repository = ComponentRepository.inMemory();
    addTearDown(repository.close);
    repository.save(_record('A-01-01'));

    repository.replaceAll([_record('B-02-03'), _record('C-03-04')]);

    expect(repository.byLocation('A-01-01'), isNull);
    expect(repository.all().map((record) => record.location), [
      'B-02-03',
      'C-03-04',
    ]);
  });

  test('replaceAll rolls back when a record cannot be encoded', () {
    final repository = ComponentRepository.inMemory();
    addTearDown(repository.close);
    repository.save(_record('A-01-01'));

    expect(
      () => repository.replaceAll([
        _record('B-02-03'),
        const ComponentRecord(
          location: 'C-03-04',
          categoryId: 'resistor',
          values: {'value': double.nan, 'quantity': 1},
        ),
      ]),
      throwsA(anything),
    );

    expect(repository.byLocation('A-01-01'), isNotNull);
    expect(repository.byLocation('B-02-03'), isNull);
  });
}

ComponentRecord _record(String location) => ComponentRecord(
  location: location,
  categoryId: 'resistor',
  values: const {'quantity': 1},
);
