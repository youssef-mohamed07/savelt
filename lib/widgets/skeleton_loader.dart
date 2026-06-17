import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class TransactionSkeletonLoader extends StatelessWidget {
  const TransactionSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 120, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 80, height: 14),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
            const SkeletonLoader(width: 80, height: 20),
          ],
        ),
      ),
    );
  }
}

class CategorySkeletonLoader extends StatelessWidget {
  const CategorySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          const SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 50, height: 12),
        ],
      ),
    );
  }
}

class ChartSkeletonLoader extends StatelessWidget {
  const ChartSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (index) => SkeletonLoader(
                  width: 20,
                  height: 40 + (index * 20).toDouble(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const SkeletonLoader(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        const SizedBox(height: 16),
        const SkeletonLoader(width: 120, height: 20),
        const SizedBox(height: 8),
        const SkeletonLoader(width: 180, height: 16),
        const SizedBox(height: 32),
        ...List.generate(
          5,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                SkeletonLoader(width: 24, height: 24),
                SizedBox(width: 16),
                Expanded(child: SkeletonLoader(width: double.infinity, height: 16)),
                SkeletonLoader(width: 24, height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

// Predefined skeleton loaders for common use cases
class SkeletonLoaders {
  static Widget transactionList({int itemCount = 5}) {
    return ListSkeletonLoader(
      itemCount: itemCount,
      itemBuilder: (context, index) => const TransactionSkeletonLoader(),
    );
  }

  static Widget categoryGrid({int itemCount = 8}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const CategorySkeletonLoader(),
    );
  }

  static Widget chart() => const ChartSkeletonLoader();
  
  static Widget profile() => const ProfileSkeletonLoader();
}