// gerencia os dados de produção em tempo real p/ o dashboard
//
// polling: a cada 5 segundos busca o último registro da api.
// Timer.periodic cria um timer q dispara na thread principal do flutter (ui thread),
// mas o await dentro do callback suspende só aquela chamada, s/ travar a ui.
//
// ciclo de vida:
//   iniciarPolling() → timer começa → a cada 5s busca api → notifica ui
//   pararPolling()   → timer cancela → para as requisições

import 'dart:async'; // p/ o Timer.periodic
import 'package:flutter/foundation.dart';
import '../models/producao_model.dart';
import '../services/api_service.dart';

class ProducaoProvider extends ChangeNotifier {
  ProducaoModel? _producao; // último registro de produção recebido
  bool    _carregando = false;
  String? _erro;
  Timer?  _timer; // referência ao timer p/ poder cancelar depois

  ProducaoModel? get producao   => _producao;
  bool           get carregando => _carregando;
  String?        get erro       => _erro;
  // ativo = true qdo o timer está rodando (mostra o badge "ao vivo")
  bool           get ativo      => _timer?.isActive ?? false;

  // inicia o polling a cada 5 segundos
  // chama imediatamente uma vez p/ n esperar o primeiro intervalo
  void iniciarPolling(String token) {
    _buscarDados(token); // primeira busca imediata

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _buscarDados(token); // repete a cada 5s
    });
  }

  // para o polling — chamar qdo sair do dashboard p/ economizar bateria e dados
  void pararPolling() {
    _timer?.cancel(); // o "?" evita null pointer se o timer n existir
    _timer = null;
  }

  // busca os dados na api e atualiza o estado
  Future<void> _buscarDados(String token) async {
    // n mostra loading nas atualizações periódicas — evita o card "piscando"
    // só mostra na primeira vez, qdo _producao ainda é null
    if (_producao == null) {
      _carregando = true;
      notifyListeners();
    }

    try {
      _producao = await ApiService.getProducaoAtual(token);
      _erro = null;
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _carregando = false;
      notifyListeners(); // avisa o dashboard p/ redesenhar
    }
  }

  // envia um comando e já força uma atualização dos dados logo em seguida
  Future<void> enviarComando(String token, String comando) async {
    try {
      await ApiService.enviarComando(token, comando);
      await _buscarDados(token); // atualiza imediatamente após o comando
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pararPolling(); // garante q o timer é cancelado qdo o provider é destruído
    super.dispose();
  }
}
