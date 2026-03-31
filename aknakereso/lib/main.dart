import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MinesweeperPage(),
    );
  }
}

class Cell {
  bool isMine;
  bool isRevealed;
  bool isFlagged;
  int adjacentMines;

  Cell({
    this.isMine = false,
    this.isRevealed = false,
    this.isFlagged = false,
    this.adjacentMines = 0,
  });
}

enum GameState { playing, won, lost }

enum Difficulty { easy, normal, hard }

class MinesweeperPage extends StatefulWidget {
  const MinesweeperPage({super.key});

  @override
  State<MinesweeperPage> createState() => _MinesweeperPageState();
}

class _MinesweeperPageState extends State<MinesweeperPage> {
  int rows = 10;
  int cols = 10;
  int mineCount = 15;

  late List<List<Cell>> grid;
  GameState gameState = GameState.playing;

  bool firstClick = true;
  bool flagMode = false;
  Difficulty difficulty = Difficulty.normal;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _setDifficulty(Difficulty diff) {
    setState(() {
      difficulty = diff;
      switch (diff) {
        case Difficulty.easy:
          rows = 8;
          cols = 8;
          mineCount = 10;
          break;
        case Difficulty.normal:
          rows = 10;
          cols = 10;
          mineCount = 15;
          break;
        case Difficulty.hard:
          rows = 12;
          cols = 12;
          mineCount = 25;
          break;
      }
      _initBoard();
    });
  }

  void _initBoard() {
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => Cell()),
    );
    firstClick = true;
    gameState = GameState.playing;
    flagMode = false;
  }

  bool _inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  void _calculateNumbers() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isMine) continue;
        int count = 0;
        for (int i = -1; i <= 1; i++) {
          for (int j = -1; j <= 1; j++) {
            int nr = r + i;
            int nc = c + j;
            if (_inBounds(nr, nc) && grid[nr][nc].isMine) count++;
          }
        }
        grid[r][c].adjacentMines = count;
      }
    }
  }

  void _placeMinesSafe(int safeR, int safeC) {
    final rand = Random();
    int placed = 0;
    while (placed < mineCount) {
      int r = rand.nextInt(rows);
      int c = rand.nextInt(cols);
      if ((r - safeR).abs() <= 1 && (c - safeC).abs() <= 1) continue;
      if (!grid[r][c].isMine) {
        grid[r][c].isMine = true;
        placed++;
      }
    }
    _calculateNumbers();
  }

  void _reveal(int r, int c) {
    if (!_inBounds(r, c)) return;
    final cell = grid[r][c];
    if (cell.isRevealed || cell.isFlagged) return;

    setState(() {
      if (firstClick) {
        _placeMinesSafe(r, c);
        firstClick = false;
      }

      cell.isRevealed = true;

      if (cell.isMine) {
        gameState = GameState.lost;
        _revealAll();
        return;
      }

      if (cell.adjacentMines == 0) {
        for (int i = -1; i <= 1; i++) {
          for (int j = -1; j <= 1; j++) {
            _reveal(r + i, c + j);
          }
        }
      }

      _checkWin();
    });
  }

  void _toggleFlag(int r, int c) {
    final cell = grid[r][c];
    if (cell.isRevealed) return;
    setState(() {
      cell.isFlagged = !cell.isFlagged;
    });
  }

  void _revealAll() {
    for (var row in grid) {
      for (var cell in row) {
        cell.isRevealed = true;
      }
    }
  }

  void _checkWin() {
    for (var row in grid) {
      for (var cell in row) {
        if (!cell.isMine && !cell.isRevealed) return;
      }
    }
    gameState = GameState.won;
  }

  void _restart() {
  setState(() {
    // új játék az aktuális difficulty alapján
    switch (difficulty) {
      case Difficulty.easy:
        rows = 8;
        cols = 8;
        mineCount = 10;
        break;
      case Difficulty.normal:
        rows = 10;
        cols = 10;
        mineCount = 15;
        break;
      case Difficulty.hard:
        rows = 12;
        cols = 12;
        mineCount = 25;
        break;
    }
    _initBoard();
  });
}

  int _flagsPlaced() {
    int count = 0;
    for (var row in grid) {
      for (var cell in row) {
        if (cell.isFlagged) count++;
      }
    }
    return count;
  }

  String _getStatusText() {
    String base;
    switch (gameState) {
      case GameState.playing:
        base = "Játék folyamatban";
        break;
      case GameState.won:
        base = "Nyertél!";
        break;
      case GameState.lost:
        base = "Vesztettél!";
        break;
    }
    int remaining = mineCount - _flagsPlaced();
    if (remaining < 0) remaining = 0;
    return "$base | Bombák hátra: $remaining";
  }

  Widget _buildCell(Cell cell) {
    if (cell.isFlagged) return const Icon(Icons.flag, color: Colors.red);
    if (!cell.isRevealed) return const SizedBox();
    if (cell.isMine) return const Icon(Icons.circle, color: Colors.black);
    if (cell.adjacentMines > 0) {
      Color color;
      switch (cell.adjacentMines) {
        case 1:
          color = Colors.blue;
          break;
        case 2:
          color = Colors.green;
          break;
        case 3:
          color = Colors.red;
          break;
        case 4:
          color = Colors.purple;
          break;
        default:
          color = Colors.brown;
      }
      return Text(
        '${cell.adjacentMines}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final gridSize = min(media.width, media.height - 250);
    final cellSize = gridSize / max(rows, cols);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aknakereső"),
        centerTitle: true,
      ),
      body: Column(
  children: [
    const SizedBox(height: 10),
    // Nehézségi választó
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<Difficulty>(
            value: difficulty,
            onChanged: (Difficulty? newDiff) {
              if (newDiff != null) _setDifficulty(newDiff);
            },
            items: Difficulty.values.map((diff) {
              String text;
              switch (diff) {
                case Difficulty.easy:
                  text = "Könnyű";
                  break;
                case Difficulty.normal:
                  text = "Normál";
                  break;
                case Difficulty.hard:
                  text = "Nehéz";
                  break;
              }
              return DropdownMenuItem(
                value: diff,
                child: Text(text),
              );
            }).toList(),
          ),
          if (gameState != GameState.playing)
            ElevatedButton(
              onPressed: _restart,
              child: const Text("Új játék"),
            ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    Text(
      _getStatusText(),
      style: const TextStyle(fontSize: 18),
    ),
    const SizedBox(height: 10),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Felfedés"),
        Switch(
          value: flagMode,
          onChanged: (value) {
            if (!firstClick) {
              setState(() {
                flagMode = value;
              });
            }
          },
        ),
        const Text("Zászló"),
      ],
    ),
    const SizedBox(height: 10),
    // Grid
    Center(
      child: SizedBox(
        width: gridSize,
        height: gridSize,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows * cols,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            int r = index ~/ cols;
            int c = index % cols;
            final cell = grid[r][c];

            return GestureDetector(
              onTap: () {
                if (gameState != GameState.playing) return;
                if (flagMode) {
                  _toggleFlag(r, c);
                } else {
                  _reveal(r, c);
                }
              },
              child: Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(1),
                color: cell.isRevealed ? Colors.grey[300] : Colors.grey[600],
                child: Center(
                  child: _buildCell(cell),
                ),
              ),
            );
          },
        ),
      ),
    ),
  ],
),
    );
  }
}