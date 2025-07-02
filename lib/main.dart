import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 32, 0, 46),
        ),
      ),
      initialRoute: "/",
      routes: {"/": (context) => const TopPage()},
    );
  }
}

class TopPage extends StatefulWidget {
  static String title = "Flutter Todo";

  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  String message = ""; // 最上段に表示するメッセージ
  List<TODO> todoList = []; // TODOリストを保持
  bool sortedDeadline = false;

  // Todoリストにタスクを表示し画面に反映する
  void addTodoList(int newId, String title, DateTime deadline) {
    setState(() {
      todoList.add(TODO(newId, title, deadline, false));
    });
  }

  // タスク追加・編集用ダイアログを生成
  void showTodoDialog({
    required BuildContext context,
    String? initialTitle, // 初期タイトル（編集の場合に使用）
    DateTime? initialDeadline, // 初期締切日（編集の場合に使用）
    required void Function(String title, DateTime deadline) onSubmit,
  }) {
    final TextEditingController textController = TextEditingController(
      text: initialTitle ?? '',
    );
    DateTime? selectedDate = initialDeadline;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("TODO"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: "Enter TODO title",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'No deadline selected'
                              : 'Deadline: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty &&
                        selectedDate != null) {
                      onSubmit(textController.text, selectedDate!);
                      Navigator.of(context).pop(); // ダイアログを閉じる
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // タスクを作成
  void addTodoDialog() {
    showTodoDialog(
      context: context,
      onSubmit: (title, deadline) {
        setState(() {
          int newId = todoList.isEmpty ? 1 : todoList.last.todoId + 1;
          todoList.add(TODO(newId, title, deadline, false));
        });
      },
    );
  }

  // タスクを編集
  void editTodoDialog(int editTodoId) {
    showTodoDialog(
      context: context,
      initialTitle: todoList[editTodoId].title,
      initialDeadline: todoList[editTodoId].deadline,
      onSubmit: (title, deadline) {
        setState(() {
          todoList[editTodoId].title = title;
          todoList[editTodoId].deadline = deadline;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(TopPage.title),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: Colors.red)),
          Expanded(
            child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                final todo = todoList[index];
                Color textColor =
                    (todo.deadline.isBefore(DateTime.now()))
                        ? Colors.red
                        : Colors.black;
                return ListTile(
                  title: Text(todo.title),
                  leading: Text(todo.todoId.toString()),
                  subtitle: Text(
                    'Deadline: ${todo.deadline.year}/${todo.deadline.month}/${todo.deadline.day}',
                    style: TextStyle(color: textColor),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: (() {
                          editTodoDialog(index);
                        }),
                        child: Text("編集"),
                      ),
                      Checkbox(
                        value: todo.isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            todoList[index].isChecked = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              // 確認ダイアログを表示して結果を取得
              bool? confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (BuildContext context) => AlertDialog(
                      content: const Text("本当に達成済みタスクを削除しますか？"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Cancelを選択
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true); // Yesを選択
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
              );

              // ユーザーがYesを選択した場合のみ削除処理を実行
              if (confirmed == true) {
                setState(() {
                  todoList.removeWhere(
                    (todo) => todo.isChecked,
                  ); // 条件を満たすタスクを削除
                });

                // 完了ダイアログを表示
                showDialog(
                  context: context,
                  builder:
                      (BuildContext context) => AlertDialog(
                        content: Text("タスクが削除されました"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      ),
                );
              }
            },
            tooltip: "deleted",
            child: const Icon(Icons.delete),
          ),

          SizedBox(height: 50, width: 50),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                if (!sortedDeadline) {
                  // 期日が早い順にソートする
                  todoList.sort((a, b) => a.deadline.compareTo(b.deadline));
                  sortedDeadline = true;
                } else {
                  // ID順にソートする
                  todoList.sort((a, b) => a.todoId.compareTo(b.todoId));
                  sortedDeadline = false;
                }
              });
            },
            tooltip: "sort",
            child: const Icon(Icons.swap_vert),
          ),
          SizedBox(height: 50, width: 50),
          FloatingActionButton(
            onPressed: addTodoDialog,
            tooltip: "Add TODO",
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class TODO {
  final int todoId;
  String title;
  DateTime deadline;
  bool isChecked;

  TODO(this.todoId, this.title, this.deadline, this.isChecked);

  @override
  String toString() {
    return 'TODO ID: $todoId, Title: $title, Deadline: $deadline, Checked: $isChecked';
  }
}
