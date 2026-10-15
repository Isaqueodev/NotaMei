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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page <= 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _moveTo(_page - 1);
      },
      child: Scaffold(
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
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart, required this.onSkip});
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => _CenteredScroll(
    children: [
      const _BrandMark(),
      const SizedBox(height: 22),
      Text(
        'Seu negócio mais claro,\num registro de cada vez.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Controle financeiro simples, gratuito e offline\npensado para a rotina de quem é MEI.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      const _InfoCard(
        icon: Icons.swap_vert,
        title: 'Registrar entradas e saídas',
        body: 'Anote o dinheiro que entra e sai do seu dia a dia com agilidade e valores em reais (R\$).',
      ),
      const _InfoCard(
        icon: Icons.category_outlined,
        title: 'Classificar negócio e pessoal',
        body: 'Separe manualmente as finanças da sua atividade MEI das contas pessoais da casa, sem complicações.',
      ),
      const _InfoCard(
        icon: Icons.notifications_none,
        title: 'Acompanhar avisos informativos',
        body: 'Monitore os meses registrados e receba alertas para organizar seu controle anual.',
      ),
      const _Tip(
        text: 'Os registros são feitos neste aparelho; cópias do sistema dependem das suas configurações. Sem exportação nesta versão, você pode perder o histórico ao trocar ou desinstalar.',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Ver como funciona'),
      ),
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
    'Informe valor, data e categoria. Seus lançamentos ficam neste aparelho.',
    'Escolha o destino de cada lançamento com um toque. Mantenha os números do seu MEI organizados sem misturar com os gastos de casa.',
    'Configure um lembrete do DAS e acompanhe a receita que você informou. Confira sempre as informações oficiais.',
  ];

  @override
  Widget build(BuildContext context) => _CenteredScroll(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
    children: [
      Row(
        children: [
          IconButton(
            onPressed: page == 0 ? null : onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'NotaMei',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NotaMeiTheme.purple,
              ),
            ),
          ),
          TextButton(onPressed: onSkip, child: const Text('Pular tour')),
        ],
      ),
      _Progress(page: page),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _titles[page],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: Text(_subtitles[page])),
      const SizedBox(height: 20),
      ..._cards(context),
      const SizedBox(height: 20),
      if (page == 0) ...[
        const _Tip(
          text: 'Sem sincronização nesta versão; cuide da segurança do aparelho e de cópias dos seus dados.',
        ),
        const SizedBox(height: 18),
      ],
      Row(
        children: [
          if (page > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: Text(page == 2 ? 'Começar a usar' : 'Próximo'),
            ),
          ),
        ],
      ),
      TextButton(onPressed: onSkip, child: const Text('Pular tour')),
    ],
  );

  List<Widget> _cards(BuildContext context) {
    if (page == 0) {
      return const [
        _InfoCard(
          icon: Icons.receipt_long_outlined,
          title: 'Exemplo de lançamentos',
          body: 'Prestação de serviço                 + R\$ 180,00\nMaterial e insumos                    - R\$ 52,00',
        ),
        _InfoCard(
          icon: Icons.phone_android,
          title: 'Armazenamento local no aparelho',
          body: 'O app não oferece sincronização própria. Verifique as opções de backup do sistema.',
        ),
      ];
    }
    if (page == 1) {
      return const [
        _InfoCard(
          icon: Icons.storefront_outlined,
          title: 'Venda de produto ou serviço',
          body: '+ R\$ 350,00  ·  Negócio',
        ),
        _InfoCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Compras do mercado ou casa',
          body: '- R\$ 180,40  ·  Pessoal',
        ),
        _Tip(
          text: 'Marcar um lançamento como pessoal retira esse valor dos resumos do negócio.',
        ),
      ];
    }
    return const [
      _InfoCard(
        icon: Icons.notifications_none,
        title: 'Lembrete mensal do DAS',
        body: 'Defina um dia conveniente para ser avisado no seu telefone. Não precisa ter internet nem cobra nada.',
      ),
      _InfoCard(
        icon: Icons.calendar_month_outlined,
        title: 'Histórico anual dos seus registros',
        body: 'Visualize a soma acumulada dos meses informados para facilitar seu controle pessoal.',
      ),
    ];
  }
}

class _Complete extends StatelessWidget {
  const _Complete({required this.onFinish, required this.onAddFirstEntry});
  final VoidCallback onFinish;
  final VoidCallback onAddFirstEntry;

  @override
  Widget build(BuildContext context) => _CenteredScroll(
    children: [
      const _BrandMark(),
      const SizedBox(height: 22),
      Text(
        'Pronto para começar',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Você já conhece o básico. Comece registrando\numa entrada ou saída.\n\nVocê pode rever o tour em Ajustes.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      FilledButton(onPressed: onFinish, child: const Text('Ir para o Início')),
      TextButton(
        onPressed: onAddFirstEntry,
        child: const Text('Adicionar primeiro lançamento'),
      ),
    ],
  );
}

class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - padding.vertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: NotaMeiTheme.palePurple,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'N',
      style: TextStyle(
        color: NotaMeiTheme.purple,
        fontSize: 25,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.page});
  final int page;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LinearProgressIndicator(
          value: (page + 1) / 3,
          color: NotaMeiTheme.purple,
          backgroundColor: NotaMeiTheme.border,
          minHeight: 4,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'Etapa ${page + 1} de 3',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NotaMeiTheme.purple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NotaMeiTheme.palePurple,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
