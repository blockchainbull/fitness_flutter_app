import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;
  
  const MetricsCard({
    Key? key,
    required this.metrics,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: metrics.map((metric) => _buildMetric(metric)).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // TODO: Navigate to detailed metrics
              },
              icon: const Icon(
                Icons.assessment,
                size: 16,
              ),
              label: const Text('View Detailed Analytics'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetric(Map<String, dynamic> metric) {
    Color metricColor;
    
    // Determine color based on status
    final status = metric['status'].toString().toLowerCase();
    if (status.contains('normal') || status.contains('good')) {
      metricColor = Colors.green;
    } else if (status.contains('moderate')) {
      metricColor = Colors.orange;
    } else if (status.contains('high') || status.contains('low')) {
      metricColor = Colors.blue;
    } else {
      metricColor = Colors.grey;
    }
    
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: metricColor.withOpacity(0.1),
            border: Border.all(
              color: metricColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              metric['value'],
              style: TextStyle(
                color: metricColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          metric['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          metric['status'],
          style: TextStyle(
            color: metricColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}