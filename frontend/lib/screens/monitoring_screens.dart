          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_tripActive) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Start Trip Verification",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cabController,
                                decoration: const InputDecoration(
                                  labelText: "Cab Registration Number",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.purple),

<truncated 2376 bytes>
                           Text(
                              _cabController.text,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _riskLevel == "high" || _riskLevel == "critical" ? Colors.red.shade100 : (_riskLevel == "medium" ? Colors.orange.shade100 : Colors.green.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _riskLevel.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _riskLevel == "high" || _riskLevel == "critical" ? Colors.red : (_riskLevel == "medium" ? Colors.orange : Colors.green),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Safety Rating: $_cabSafetyRating ★",
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
