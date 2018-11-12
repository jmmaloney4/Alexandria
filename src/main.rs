extern crate clap;
use clap::{App, Arg, SubCommand};

use std::path::{Path, PathBuf};
use std::fs;

#[macro_use] extern crate serde_derive;

const FOLDER_NAME: &str = ".alex";
const CONFIG_FILE: &str = "settings.toml";
const DEFAULT_DB_PATH: &str = "library.db";

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

    let current_dir = std::env::current_dir().expect("Failed to get current directory").clone();

    let repo = Repository::open(current_dir).expect("Failed to open repo");

}

struct Repository {
    path: PathBuf,
}

impl Repository {
    fn repo_dir(&self) -> PathBuf {
        let mut rv = PathBuf::new();
        rv.push(self.path.clone());
        rv.push(Path::new(FOLDER_NAME));
        rv
    }

    fn db_path(&self) -> PathBuf {
        let mut rv = self.repo_dir();
        rv.push(Path::new(DEFAULT_DB_PATH));
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