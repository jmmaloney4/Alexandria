extern crate clap;
use clap::{App, Arg, SubCommand};

use std::path::{Path, PathBuf};
use std::fs;

use std::fs::File;
use std::io::prelude::*;

#[macro_use] extern crate serde_derive;

extern crate ring;
use ring::digest::*;

const REPO_DIR: &str = ".alex";
const CONFIG_FILE: &str = "settings.toml";
const OBJECT_DIR: &str = "obj";

fn main() {
    let matches = App::new("alex")
        .version("0.0.1")
        .author("Jack Maloney")
        .about("Manages files and shit")
        .arg(
            Arg::with_name("v")
                .short("v")
                .multiple(true)
                .help("Sets the level of verbosity"),
        ).arg(
            Arg::with_name("change-directory")
                .short("C")
                .takes_value(true)
                .value_name("path")
                .help("Run this command inside of the directory at <path>"),
        ).subcommand(
            SubCommand::with_name("hash-object")
                .about("Hashes a given data blob")
                .arg(Arg::with_name("file").index(1))
                .arg(
                    Arg::with_name("stdin")
                        .long("stdin")
                        .help("Take input from stdin instead of a file"),
                ),
        ).get_matches();

    // Vary the output based on how many times the user used the "verbose" flag
    // (i.e. 'myprog -v -v -v' or 'myprog -vvv' vs 'myprog -v'
    match matches.occurrences_of("v") {
        0 => println!("No verbose info"),
        1 => println!("Some verbose info"),
        2 => println!("Tons of verbose info"),
        3 | _ => println!("Don't be crazy"),
    }

    if let Some(matches) = matches.subcommand_matches("hash-object") {
        let mut buffer = String::new();

         if matches.is_present("stdin") {
            let stdin = std::io::stdin();
            let mut handle = stdin.lock();

            handle.read_to_string(&mut buffer).expect("Error reading from stdin");
        } else if let Some(filename) = matches.value_of("file") {
            let mut f = File::open(filename).expect("file not found");
            
            f.read_to_string(&mut buffer)
                .expect("something went wrong reading the file");
        } else {
            panic!("Need input");
        }

        println!("{}", buffer);

        let sha = digest(&SHA256, buffer.as_ref());
        println!("{:x?}", sha.as_ref());
        println!("{:?}", sha256_to_path(&sha));

        let current_dir = std::env::current_dir().expect("Failed to get current directory").clone();

    }

    /*

    let sha = digest(&SHA256, buffer.as_ref());
            println!("{:x?}", sha.as_ref());

    let sha = digest(&SHA256, contents.as_ref());
    println!("{:?}", sha);
    
    let current_dir = std::env::current_dir().expect("Failed to get current directory").clone();

    let repo = Repository::open(current_dir).expect("Failed to open repo");

    */
}

struct Repository {
    path: PathBuf,
}

impl Repository {
    fn repo_dir(&self) -> PathBuf {
        let mut rv = PathBuf::new();
        rv.push(self.path.clone());
        rv.push(Path::new(REPO_DIR));
        rv
    }

    fn working_dir(&self) -> PathBuf {
        self.path.clone()
    }

    fn open<P: AsRef<Path>>(path: P) -> Option<Repository> {
        let mut repo = Repository { path: path.as_ref().to_path_buf() };
    
        if !repo.repo_dir().exists() {
            return None;
        }

        return Some(repo);
    }

    fn create<P: AsRef<Path>>(path: P) -> Option<Repository> {
        let mut repo = Repository { path: path.as_ref().to_path_buf() };

        fs::create_dir(repo.repo_dir()).expect("Failed to create directory");

        return Some(repo);
    }
}

fn sha256_to_path(sha256: &Digest) -> PathBuf {
    let buf = sha256.as_ref();
    let prefix_bytes = &buf[0];
    let suffix_bytes = &buf[1..];

    let prefix = &format!("{:x}", prefix_bytes);
    let suffix = u8to_lower_hex(suffix_bytes);
    let path_string = format!("{}/{}", prefix, suffix);

    PathBuf::from(path_string)
}

fn u8to_lower_hex(input: &[u8]) -> String {
    let mut s = String::new();
    for &byte in input {
        s.push_str(format!("{:x}", byte).as_ref());
    }
    return s;
}