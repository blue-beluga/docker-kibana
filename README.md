
# [<img src=".bluebeluga.png" height="100" width="200" style="border-radius: 50%;" alt="@fancyremarker" />](https://github.com/blue-beluga/docker-vault) bluebeluga/vault

Alpine Linux image with [Kibana](https://www.elastic.co/products/kibana).

## Security considerations

This app is configured through two environment variables: `AUTH_CREDENTIALS`
and `DATABASE_URL`. The former is used to authenticate Kibana users, and the
latter is used to make requests to a backend Elasticsearch instance.

In other words, **any user that can log in to Kibana can execute queries
against the upstream Elasticsearch instance using Kibana's credentials**.

This is probably what you want if you're deploying Kibana, but it means you
should make sure you choose strong passwords for `AUTH_CREDENTIALS`.


## Installation

To run as an app on Aptible:

 1. Create an app in your [Aptible dashboard](https://dashboard.aptible.com) for Kibana. In the
    steps that follow, we'll use &lt;YOUR_KIBANA_APP_HANDLE&gt; anywhere that you should substitute the
    actual app handle the results from this step in the instructions.

 2. Use the [Aptible CLI](https://github.com/aptible/aptible-cli) to set AUTH_CREDENTIALS to the
    username/password you want to use to access the app. To set the user to "foo" and password
    to "bar", run:

    ```
    aptible config:set AUTH_CREDENTIALS=foo:bar --app <YOUR_KIBANA_APP_HANDLE>
    ```

 3. Use the [Aptible CLI](https://github.com/aptible/aptible-cli) to set DATABASE_URL to the
    URL of your Elasticsearch instance on Aptible (this is just the connection string presented
    in the Aptible dashboard when you select your Elasticsearch instance). If your URL is
    http://user:password@example.com, run:

    ```
    aptible config:set DATABASE_URL=http://user:password@example.com --app <YOUR_KIBANA_APP_HANDLE>
    ```

 4. (Optional) Update your configuration to specify a Kibana version. If you are
    using Elasticsearch 1.x, then use Kibana 4.1, otherwise, use Kibana 4.4. If
    you don't set this, this app will auto-detect your Elasticsearch version
    from `DATABASE_URL`, so it's entirely fine to leave it empty.

    ```
    # For Elasticsearch 1.x
    aptible config:set KIBANA_ACTIVE_VERSION=41 --app <YOUR_KIBANA_APP_HANDLE>

    # For Elasticsearch 2.x
    aptible config:set KIBANA_ACTIVE_VERSION=44 --app <YOUR_KIBANA_APP_HANDLE>
    ```

    If you don't specify a version, this app will try to guess one based on your
    `DATABASE_URL`, or fall back to the most recent Kibana version.

 5. (Optional) Kibana config options can be set for `default_route` and `kibana_index` which are then saved to the config.js:

    ```
    aptible config:set DEFAULT_ROUTE=/path/to/default --app <YOUR_KIBANA_APP_HANDLE>
    aptible config:set KIBANA_INDEX=your_index --app <YOUR_KIBANA_APP_HANDLE>
    ```

 6. Clone this repository and push it to your Aptible app:

    ```
    git clone https://github.com/aptible/docker-kibana.git
    cd docker-kibana
    git remote add aptible git@beta.aptible.com:<YOUR_KIBANA_APP_HANDLE>.git
    git push aptible master
    ```


## Next steps

You should be up and running now. If you have a default `*.on-aptible.com` VHOST, you're done. If not, add a custom VHOST to expose your Kibaba app to the Internet.

If you're new to Kibana, try working through the
[Kibana 10 minute walk through](http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html) as an introduction. To jump in to
a view of your recent log messages, you can start by clicking the "Discover" tab, which should default to viewing all log messages, most recent
first.
