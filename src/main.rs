use seccomp::{Action, Compare, Context, Op, Rule};

fn main() {
    let mut ctx = Context::default(Action::Allow).unwrap();
    let rule = Rule::new(
        libc::SYS_clone as usize,
        Compare::arg(0).with(0).using(Op::Gt).build().unwrap(),
        Action::Errno(libc::EPERM), /* return EPERM */
    );
    ctx.add_rule(rule).unwrap();
    ctx.load().unwrap();

    let forked = unsafe { libc::fork() };
    if forked == -1 {
        println!("Fork did not work");
        std::process::exit(1)
    }

    if forked == 0 {
        println!("Child");
    } else {
        println!("Parent");
    }
}
