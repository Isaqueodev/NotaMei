import 'package:flutter/material.dart';
import 'package:notamei/theme/notamei_theme.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onFinish,
    required this.onAddFirstEntry,
    this.showWelcome = true,
  });

  final VoidCallback onFinish;
  final VoidCallback onAddFirstEntry;
  final bool showWelcome;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late int _page = widget.showWelcome ? -1 : 0;

  void _moveTo(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _page <= 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _page > 0) _moveTo(_page - 1);
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(_page),
            child: _page == -1
                ? _Welcome(onStart: () => _moveTo(0), onSkip: widget.onFinish)
                : _page == 3
                ? _Complete(
                    onFinish: widget.onFinish,
                    onAddFirstEntry: widget.onAddFirstEntry,
                  )
                : _TourStep(
                    page: _page,
                    onNext: () => _moveTo(_page + 1),
                    onBack: () => _moveTo(_page - 1),
                    onSkip: widget.onFinish,
                  ),
          ),
        ),
      ),
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart, required this.onSkip});
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => _EditorialScroll(
    children: [
      const _BrandMark(),
      const SizedBox(height: 24),
      Text(
        'Seu negócio mais claro,\num registro de cada vez.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'Um caderno de entradas e saídas para a rotina de quem é MEI.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      const _Sheet(
        children: [
          _InfoRow(
            number: '1',
            title: 'Registro manual e direto',
            body: 'Você anota cada entrada e saída. Sem conexão com bancos ou leitura automática.',
          ),
          Divider(),
          _InfoRow(
            number: '2',
            title: 'Classificar negócio e pessoal',
            body: 'Separe os registros da atividade MEI dos gastos de casa.',
          ),
          Divider(),
          _InfoRow(
            number: '3',
            title: 'Dados neste aparelho',
            body:
                'Sem cadastro, sincronização ou backup próprios nesta versão.',
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _Tip(
        text: 'Limpar os dados ou desinstalar o app pode apagar seu histórico. Não há backup próprio; cópias do sistema dependem das suas configurações.',
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: onStart, child: const Text('Ver como funciona')),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: onSkip, child: const Text('Começar sem tour')),
    ],
  );
}

class _TourStep extends StatelessWidget {
  const _TourStep({
    required this.page,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });
  final int page;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  static const _titles = [
    'Registre o que entra e sai',
    'Separe negócio e pessoal',
    'Acompanhe seus avisos',
  ];
  static const _subtitles = [
    'Informe valor, data, categoria e uma observação opcional. Seus lançamentos ficam neste aparelho.',
    'Você classifica cada lançamento manualmente. Sem integração com conta de banco ou separação financeira externa.',
    'Acompanhe as entradas do negócio que você informou e configure um lembrete pessoal do DAS.',
  ];

  @override
  Widget build(BuildContext context) => _EditorialScroll(
    children: [
      Row(
        children: [
          if (page > 0)
            IconButton(
              tooltip: 'Etapa anterior',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          const Expanded(
            child: Text(
              'NotaMei',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onSkip,
              child: const Text('Pular tour'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Progress(page: page),
      const SizedBox(height: 32),
      Text(_titles[page], style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text(_subtitles[page]),
      const SizedBox(height: 24),
      ..._cards(),
      const SizedBox(height: 24),
      if (page > 0) ...[
        OutlinedButton(onPressed: onBack, child: const Text('Voltar')),
        const SizedBox(height: 8),
      ],
      FilledButton(
        onPressed: onNext,
        child: Text(page == 2 ? 'Começar a usar' : 'Próximo'),
      ),
      TextButton(onPressed: onSkip, child: const Text('Pular tour')),
    ],
  );

  List<Widget> _cards() {
    if (page == 0) {
      return const [
        _Sheet(
          children: [
            _SheetTitle(
              'Exemplo de registros',
              subtitle: 'Demonstração • valores fictícios',
            ),
            Divider(),
            _LedgerRow(
              title: 'Venda de bolo no pote',
              scope: 'Negócio',
              value: '+ R\$ 180,00',
              income: true,
            ),
            Divider(),
            _LedgerRow(
              title: 'Ingredientes e embalagens',
              scope: 'Negócio',
              value: '− R\$ 52,00',
              income: false,
            ),
          ],
        ),
        SizedBox(height: 16),
        _Tip(
          text: 'Armazenamento local no aparelho. Sem sincronização automática ou backup próprio. Limpar os dados ou desinstalar pode apagar os registros.',
        ),
      ];
    }
    if (page == 1) {
      return const [
        _Sheet(
          children: [
            _SheetTitle(
              'Cada registro no seu lugar',
              subtitle: 'Demonstração • classificação manual',
            ),
            Divider(),
            _LedgerRow(
              title: 'Serviço de consultoria',
              scope: 'Negócio',
              value: '+ R\$ 350,00',
              income: true,
            ),
            Divider(),
            _LedgerRow(
              title: 'Supermercado da família',
              scope: 'Pessoal',
              value: '− R\$ 180,40',
              income: false,
            ),
          ],
        ),
        SizedBox(height: 16),
        _Tip(
          text: 'Marcar um lançamento como pessoal retira esse valor dos resumos do negócio. Em Todos, você consulta Negócio + Pessoal.',
        ),
      ];
    }
    return const [
      _Sheet(
        children: [
          _InfoRow(
            number: '01',
            title: 'Histórico anual dos seus registros',
            body: 'Soma apenas das entradas do negócio informadas por você. Não é validação fiscal; mês sem registro não comprova ausência de movimento.',
          ),
          Divider(),
          _InfoRow(
            number: '02',
            title: 'Lembrete mensal do DAS',
            body: 'Você escolhe o dia e a hora nas configurações. Nenhuma permissão é solicitada durante o tour.',
          ),
        ],
      ),
      SizedBox(height: 16),
      _Tip(
        text: 'O dia escolhido é pessoal, não o vencimento oficial. O lembrete não comprova pagamento e sua entrega não é garantida: depende das permissões e das regras do Android.',
      ),
    ];
  }
}

class _Complete extends StatelessWidget {
  const _Complete({required this.onFinish, required this.onAddFirstEntry});
  final VoidCallback onFinish;
  final VoidCallback onAddFirstEntry;

  @override
  Widget build(BuildContext context) => _EditorialScroll(
    children: [
      const _BrandMark(),
      const SizedBox(height: 24),
      Text(
        'Pronto para começar',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'Seu caderno de entradas e saídas está pronto para uso neste celular.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      const _Sheet(
        children: [
          _InfoRow(
            number: '→',
            title: 'Você encontra em Ajustes',
            body: 'Reveja o tour, configure o lembrete do DAS e consulte as informações sobre os dados locais.',
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _Tip(
        text: 'Sem sincronização ou backup próprios. Cuide dos registros: limpar os dados ou desinstalar o app pode apagar o histórico.',
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: onAddFirstEntry,
        child: const Text('Adicionar primeiro lançamento'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: onFinish,
        child: const Text('Ir para o Início'),
      ),
    ],
  );
}

class _EditorialScroll extends StatelessWidget {
  const _EditorialScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: Theme.of(context).textTheme.bodyLarge,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Image.asset(
        'assets/brand/notamei.png',
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        semanticLabel: 'Marca NotaMei',
      ),
      const SizedBox(height: 8),
      Text('NotaMei', style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.page});
  final int page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        label: 'Etapa ${page + 1} de 3',
        child: Text(
          '${page + 1}/3',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: (page + 1) / 3,
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: NotaMeiTheme.border,
        minHeight: 3,
      ),
    ],
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.number,
    required this.title,
    required this.body,
  });
  final String number;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, {required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.title,
    required this.scope,
    required this.value,
    required this.income,
  });
  final String title;
  final String scope;
  final String value;
  final bool income;
  @override
  Widget build(BuildContext context) {
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(scope, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    final amount = Text(
      value,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: income ? NotaMeiTheme.income : NotaMeiTheme.expense,
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: amount),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: description),
              const SizedBox(width: 12),
              amount,
            ],
          );
        },
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
