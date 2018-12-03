# Deprecated in favour of the better [aws-lambda-ocaml-runtime](https://github.com/anmonteiro/aws-lambda-ocaml-runtime)

## AWS Lambda Ocaml Runtime

Ocaml implementation of the lambda runtime API

## Building and Installing the Runtime

Since AWS Lambda runs on GNU/Linux, you should build this runtime library and your logic on GNU/Linux as well.
Note that you can also build it using docker, see the example project to know more about it https://github.com/vanwalj/aws-lambda-ocaml-example

And here is how a sample `main.ml` would look like:

```ocaml
let handler body:_ = Lwt.return (AwsLambda.Bootstrap.Success "{}")

let () = Lwt_main.run (AwsLambda.Bootstrap.run handler)
```

## Details

The project simply expose one module with one function and one variant, and that's it !

`AwsLambda.Bootstrap.run` is a function which expect as a single parameter a function which will take a `string` and return an `AwsLambda.Bootstrap.outcome Lwt.t` and which will be called whenever the lambda is invoked.

## License

This library is licensed under the MIT License.
