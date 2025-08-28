// Rule 1: Add rekernel header includes
@@
#include <uapi/linux/android/binder.h>
+ #ifdef CONFIG_REKERNEL
+ #include "../rekernel/rekernel.h"
+ #endif /* CONFIG_REKERNEL */

// Rule 2: Add rekernel transaction function
@@
identifier proc, tsk;
@@
+ #ifdef CONFIG_REKERNEL
+ void rekernel_binder_transaction(bool reply, struct binder_transaction *t,
+                               struct binder_node *target_node,
+                               struct binder_transaction_data *tr) {
+   struct binder_proc *to_proc;
+   struct binder_alloc *target_alloc;
+   if (!t->to_proc)
+     return;
+   to_proc = t->to_proc;
+ 
+   if (reply) {
+     binder_reply_handler(task_tgid_nr(current), current, 
+                         to_proc->pid, to_proc->tsk, false, tr);
+   } else if (t->from) {
+     if (t->from->proc) {
+       binder_trans_handler(t->from->proc->pid, t->from->proc->tsk,
+                          to_proc->pid, to_proc->tsk, false, tr);
+     }
+   } else { // oneway=1
+     binder_trans_handler(task_tgid_nr(current), current,
+                         to_proc->pid, to_proc->tsk, true, tr);
+ 
+     target_alloc = &to_proc->alloc;
+     if (target_alloc->free_async_space < 
+         (target_alloc->buffer_size / 10 + 0x300)) {
+       binder_overflow_handler(task_tgid_nr(current), current,
+                             to_proc->pid, to_proc->tsk, true, tr);
+     }
+   }
+ }
+ #endif /* CONFIG_REKERNEL */

// Rule 3: Add transaction flag check
@@
- if ((t1->flags & t2->flags & (TF_ONE_WAY | TF_UPDATE_TXN)) != TF_ONE_WAY)
+ #ifdef CONFIG_REKERNEL
+ if ((t1->flags & t2->flags & TF_ONE_WAY) != TF_ONE_WAY || !t1->to_proc || !t2->to_proc)
+ #else
+ if ((t1->flags & t2->flags & (TF_ONE_WAY | TF_UPDATE_TXN)) != TF_ONE_WAY)
+ #endif /* CONFIG_REKERNEL */

// Rule 4: Add rekernel transaction call
@@
expression reply, t, target_node, tr;
@@
  trace_binder_transaction(reply, t, target_node);
+ #ifdef CONFIG_REKERNEL
+ rekernel_binder_transaction(reply, t, target_node, tr);
+ #endif /* CONFIG_REKERNEL */
