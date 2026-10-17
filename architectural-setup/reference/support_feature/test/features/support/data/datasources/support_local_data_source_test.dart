import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/features/support/data/datasources/support_local_data_source.dart';
import 'package:template_app/features/support/data/models/support_content_model.dart';

import '../../../../helpers/fake_local_cache.dart';

void main() {
  late FakeLocalCache cache;
  late SupportLocalDataSourceImpl dataSource;

  setUp(() {
    cache = FakeLocalCache();
    dataSource = SupportLocalDataSourceImpl(cache);
  });

  test('a miss reads as null', () async {
    expect(await dataSource.readSupport(), isNull);
  });

  test('the saved content reads back equal', () async {
    const model = SupportContentModel(
      intro: 'Hi',
      channels: [
        SupportChannelModel(
          kind: 'phone',
          label: 'Phone',
          value: '+91 90000 00000',
          url: 'tel:+919000000000',
        ),
      ],
      faqs: [SupportFaqModel(question: 'Q', answer: 'A')],
    );

    await dataSource.writeSupport(model);
    final read = await dataSource.readSupport();

    expect(read!.toJson(), model.toJson());
  });
}
