import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/app.dart';

void main() {
  testWidgets('TaskManagerApp can be created', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());

    expect(find.byType(TaskManagerApp), findsOneWidget);
  });
}