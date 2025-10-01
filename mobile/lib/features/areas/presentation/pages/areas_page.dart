import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/areas_cubit.dart';
import '../cubits/areas_state.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AreasCubit>(
      create: (_) => AreasCubit(sl<AreaRepository>())..fetchAreas(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text("My Areas")),
            body: BlocBuilder<AreasCubit, AreasState>(
              builder: (context, state) {
                if (state is AreasLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AreasError) {
                  return Center(
                    child: Text(state.message, style: const TextStyle(color: Colors.red)),
                  );
                } else if (state is AreasLoaded) {
                  final areas = state.areas;
                  if (areas.isEmpty) {
                    return const Center(child: Text("No automation configured."));
                  }
                  return ListView.builder(
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return ListTile(
                        title: Text(area.name),
                        subtitle: Text(area.isActive ? "Active" : "Inactive"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                              context.push('/areas/edit', extra: area);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                context.read<AreasCubit>().removeArea(area.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push('/areas/new'),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
