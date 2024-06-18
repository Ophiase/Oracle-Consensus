fn show_array<T, +Copy<T>, +Drop<T>, +core::fmt::Display<T>>(
    array: Array<T>) {
    
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        print!("{}, ", *array.at(i));

        i += 1;
    };
}

fn show_tuple_array<T, +Copy<T>, +Drop<T>, +core::fmt::Display<T>>(
    array: Array<(usize, T)>) {
    
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        let (index, value) = *array.at(i);
        print!("({}, {}), ", index, value);

        i += 1;
    };
}