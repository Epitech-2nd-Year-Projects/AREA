import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/di/injector.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/areas_cubit.dart';
import '../cubits/areas_state.dart';
import '../../domain/entities/area.dart';
import '../widgets/area_card.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AreasCubit>(
      create: (_) => AreasCubit(sl<AreaRepository>())..fetchAreas(),
      child: const _AreasScreen(),
    );
  }
}

class _AreasScreen extends StatelessWidget {
  const _AreasScreen();

  Future<void> _openCreate(BuildContext context) async {
    final bool? refreshed = await context.pushNamed('area-new');
    if (refreshed == true && context.mounted) {
      context.read<AreasCubit>().fetchAreas();
    }
  }

  Future<void> _openEdit(BuildContext context, Area area) async {
    final bool? refreshed = await context.pushNamed('area-edit', extra: area);
    if (refreshed == true && context.mounted) {
      context.read<AreasCubit>().fetchAreas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Areas')),
      body: BlocBuilder<AreasCubit, AreasState>(
        builder: (context, state) {
          if (state is AreasLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AreasError) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: Colors.red)),
            );
          }
          if (state is AreasLoaded) {
            final areas = state.areas;

            if (areas.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => context.read<AreasCubit>().fetchAreas(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No automation configured.')),
                    SizedBox(height: 600),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AreasCubit>().fetchAreas(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 96, top: 8),
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: AreaCard(
                      area: area,
                      onEdit: () => _openEdit(context, area),
                      onDelete: () async {
                        await context.read<AreasCubit>().removeArea(area.id);
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('New'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }
}
