import 'package:baleadafit/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  testWidgets('renders the label above the field with its icon', (
    tester,
  ) async {
    await pumpField(
      tester,
      const AppTextField(label: 'Correo electrónico', labelIcon: Icons.mail),
    );

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.byIcon(Icons.mail), findsOneWidget);

    final labelY = tester.getCenter(find.text('Correo electrónico')).dy;
    final fieldY = tester.getCenter(find.byType(TextFormField)).dy;
    expect(labelY, lessThan(fieldY));
  });

  testWidgets('renders a trailing widget at the end of the label row', (
    tester,
  ) async {
    await pumpField(
      tester,
      AppTextField(
        label: 'Contraseña',
        trailing: TextButton(onPressed: () {}, child: const Text('Olvidé mi clave')),
      ),
    );

    expect(find.text('Olvidé mi clave'), findsOneWidget);
    final labelX = tester.getCenter(find.text('Contraseña')).dx;
    final trailingX = tester.getCenter(find.text('Olvidé mi clave')).dx;
    expect(labelX, lessThan(trailingX));
  });

  testWidgets('shows the validator message when the form is invalid', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await pumpField(
      tester,
      Form(
        key: formKey,
        child: AppTextField(
          label: 'Correo',
          validator: (value) =>
              value == null || value.isEmpty ? 'Escribí tu correo' : null,
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Escribí tu correo'), findsOneWidget);
  });

  testWidgets('fires onFieldSubmitted with the typed value', (tester) async {
    String? submitted;

    await pumpField(
      tester,
      AppTextField(
        label: 'Correo',
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (value) => submitted = value,
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'sofia@demo.hn');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'sofia@demo.hn');
  });

  testWidgets('forwards obscureText and autofillHints to the field', (
    tester,
  ) async {
    await pumpField(
      tester,
      const AppTextField(
        label: 'Contraseña',
        obscureText: true,
        autofillHints: [AutofillHints.password],
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
    expect(editable.autofillHints, [AutofillHints.password]);
  });
}
