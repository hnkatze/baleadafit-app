import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// "Tap to search and select one item" field, for unbounded lists where a
/// dropdown does not fit.
///
/// Collapsed it is a label over a tappable box. Tapping opens a bottom sheet
/// with a search field; nothing is fetched until the query has
/// [minimoCaracteres] characters, and typing is debounced so a word makes one
/// call. Choosing a result calls [onElegido] and closes the sheet.
class AppSearchSelectField<T> extends StatefulWidget {
  const AppSearchSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.buscar,
    required this.etiquetaDe,
    required this.onElegido,
    this.valor,
    this.buscarIcono = Icons.search,
    this.mensajeCorto = 'Escribí al menos 2 letras',
    this.mensajeVacio = 'Sin resultados',
    this.mensajeError = 'No pudimos buscar.',
  });

  /// Shown above the collapsed box.
  final String label;

  /// Placeholder of the search field inside the sheet.
  final String hint;

  /// Runs the search for a query of at least two characters.
  final Future<List<T>> Function(String consulta) buscar;

  /// The text drawn for an item, in the list.
  final String Function(T item) etiquetaDe;

  final ValueChanged<T> onElegido;

  /// Label of the already-selected item; null when there is none.
  final String? valor;

  final IconData buscarIcono;
  final String mensajeCorto;
  final String mensajeVacio;
  final String mensajeError;

  /// Characters needed before the first call.
  static const int minimoCaracteres = 2;

  /// Wait after the last keystroke before searching.
  static const Duration espera = Duration(milliseconds: 300);

  @override
  State<AppSearchSelectField<T>> createState() =>
      _AppSearchSelectFieldState<T>();
}

class _AppSearchSelectFieldState<T> extends State<AppSearchSelectField<T>> {
  Future<void> _abrir() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _Hoja<T>(
        hint: widget.hint,
        buscarIcono: widget.buscarIcono,
        mensajeCorto: widget.mensajeCorto,
        mensajeVacio: widget.mensajeVacio,
        mensajeError: widget.mensajeError,
        buscar: widget.buscar,
        etiquetaDe: widget.etiquetaDe,
        onElegido: (item) {
          widget.onElegido(item);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final valor = widget.valor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs + 2),
        InkWell(
          onTap: _abrir,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            height: AppDimensions.fieldHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  widget.buscarIcono,
                  size: AppDimensions.iconSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _Fase { corto, cargando, vacio, error, datos }

class _Hoja<T> extends StatefulWidget {
  const _Hoja({
    required this.hint,
    required this.buscarIcono,
    required this.mensajeCorto,
    required this.mensajeVacio,
    required this.mensajeError,
    required this.buscar,
    required this.etiquetaDe,
    required this.onElegido,
  });

  final String hint;
  final IconData buscarIcono;
  final String mensajeCorto;
  final String mensajeVacio;
  final String mensajeError;
  final Future<List<T>> Function(String consulta) buscar;
  final String Function(T item) etiquetaDe;
  final ValueChanged<T> onElegido;

  @override
  State<_Hoja<T>> createState() => _HojaState<T>();
}

class _HojaState<T> extends State<_Hoja<T>> {
  Timer? _debounce;
  _Fase _fase = _Fase.corto;
  List<T> _items = const [];

  /// Identifies the latest search so a slow, stale answer is dropped.
  int _busqueda = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _alCambiar(String texto) {
    _debounce?.cancel();
    final consulta = texto.trim();
    final busqueda = ++_busqueda;

    if (consulta.length < AppSearchSelectField.minimoCaracteres) {
      setState(() => _fase = _Fase.corto);
      return;
    }

    setState(() => _fase = _Fase.cargando);
    _debounce = Timer(AppSearchSelectField.espera, () async {
      try {
        final items = await widget.buscar(consulta);
        if (!mounted || busqueda != _busqueda) return;
        setState(() {
          _items = items;
          _fase = items.isEmpty ? _Fase.vacio : _Fase.datos;
        });
      } catch (_) {
        if (!mounted || busqueda != _busqueda) return;
        setState(() => _fase = _Fase.error);
      }
    });
  }

  Widget _mensaje(String texto) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _resultados() {
    switch (_fase) {
      case _Fase.corto:
        return _mensaje(widget.mensajeCorto);
      case _Fase.cargando:
        return const Padding(
          padding: EdgeInsets.all(AppDimensions.spaceLg),
          child: Center(child: CircularProgressIndicator()),
        );
      case _Fase.vacio:
        return _mensaje(widget.mensajeVacio);
      case _Fase.error:
        return _mensaje(widget.mensajeError);
      case _Fase.datos:
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _items.length,
          itemBuilder: (context, indice) {
            final item = _items[indice];
            return ListTile(
              title: Text(widget.etiquetaDe(item)),
              onTap: () => widget.onElegido(item),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceMd,
          0,
          AppDimensions.spaceMd,
          AppDimensions.spaceMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: true,
              onChanged: _alCambiar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: Icon(
                  widget.buscarIcono,
                  size: AppDimensions.iconSm,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alto * 0.5),
              child: _resultados(),
            ),
          ],
        ),
      ),
    );
  }
}
